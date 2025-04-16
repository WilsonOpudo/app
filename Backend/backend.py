# Import necessary libraries and modules
import logging
import os
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pymongo import MongoClient
from datetime import datetime, timedelta
from typing import List
from fastapi import Query
from passlib.context import CryptContext
from bson import ObjectId
from model import User, UserResponse, Appointment, AppointmentResponse, Class, ClassResponse
from pymongo.server_api import ServerApi
from model.models import LoginModel
from model.models import Enrollment  
from model.models import AvailableSlot
from fastapi.middleware.cors import CORSMiddleware
from fastapi.encoders import jsonable_encoder
from fastapi import Body
from fastapi import WebSocket, WebSocketDisconnect, Depends
from typing import List, Dict
from pymongo import MongoClient
from datetime import timedelta
from datetime import datetime
from model.models import Notification
from fastapi import APIRouter

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logging.info(f"🔌 User connected: {user_id}")

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_connections:
            self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logging.info(f"❌ User disconnected: {user_id}")

    async def send_personal_message(self, message: str, user_id: str):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                await connection.send_text(message)

    async def broadcast(self, message: str):
        for conns in self.active_connections.values():
            for connection in conns:
                await connection.send_text(message)

manager = ConnectionManager()

# Load environment variables
load_dotenv(dotenv_path=".env")
app = FastAPI()
logging.basicConfig(level=logging.INFO)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Or be strict with actual frontend origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# MongoDB Connection
MONGODB_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGODB_URI, server_api=ServerApi('1'))
try:
    client.admin.command('ping')
    print("Connected to MongoDB!")
except Exception as e:
    print(e)

db = client['MeetMeDB']
users_collection = db['users']
appointments_collection = db['appointments']
classes_collection = db['classes']
enrollments_collection = db['enrollments']
available_slots_collection = db["available_slots"]
chat_messages_collection = db["chat_messages"]
notifications_collection = db["notifications"]

print("🔗 Connected to Mongo URI:", MONGODB_URI)
print("📂 Using database:", db.name)

import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.on_event("startup")
async def startup_event():
    logger.info("🚀 FastAPI server starting up...")

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

############################ API Endpoints ############################

@app.get("/")
async def read_root():
    return {"message": "Welcome to the FastAPI application!"}

@app.post("/accounts", response_model=UserResponse)
async def create_account(user: User):
    if users_collection.find_one({"email": user.email}):
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(user.password)
    user_dict = user.dict()
    user_dict["password"] = hashed_password
    users_collection.insert_one(user_dict)
    return UserResponse(email=user.email, username=user.username, role=user.role)

@app.post("/login")
async def login(user: LoginModel):
    found = users_collection.find_one({"email": user.email})
    if not found or not verify_password(user.password, found['password']):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    return {
    "message": "Login successful",
    "email": found["email"],
    "role": found["role"],
    "username": found["username"]  # ✅ include this
}





@app.post("/appointments", response_model=AppointmentResponse)
async def create_appointment(appointment: Appointment):
    start_time = appointment.appointment_date
    end_time = start_time + timedelta(minutes=30)

    if (end_time - start_time).total_seconds() != 1800:
        raise HTTPException(status_code=400, detail="Appointment must be exactly 30 minutes")

    # 🛑 Check if the student already booked this slot
    existing =  appointments_collection.find_one({
        "student_email": appointment.student_email,
        "course_id": appointment.course_id,
        "appointment_date": start_time.isoformat()
    })
    if existing:
        raise HTTPException(status_code=400, detail="You already booked this slot")

    # ⛔ Prevent double booking by removing the slot *only if it exists*
    date = start_time.strftime("%Y-%m-%d")
    time = start_time.strftime("%H:%M")

    deleted_slot =  available_slots_collection.find_one_and_delete({
        "course_id": appointment.course_id,
        "date": date,
        "time": time
    })

    if not deleted_slot:
        raise HTTPException(status_code=409, detail="Slot already booked by another student")

    # ✅ Save the appointment
    appointment_dict = appointment.dict()
    appointment_dict["appointment_date"] = start_time.isoformat()
    result =  appointments_collection.insert_one(appointment_dict)
    appointment_dict["id"] = str(result.inserted_id)

    notifications_collection.insert_one({
        "recipient_email": deleted_slot["professor_email"],
        "title": "📅 New Appointment Booked",
        "message": f"{appointment.student_name} booked an appointment for {appointment.course_name} at {time}.",
        "type": "booking",
        "timestamp": datetime.utcnow(),
        "read": False
    })
    
    return {
        "id": appointment_dict["id"],
        "student_name": appointment.student_name,
        "student_email": appointment.student_email,
        "course_id": appointment.course_id,
        "course_name": appointment.course_name,
        "professor_name": appointment.professor_name,
        "appointment_date": start_time.isoformat()
    }


@app.post("/classes", response_model=ClassResponse)
async def create_class(cls: Class):
    logging.info(f"Attempting to create class: {cls.dict()}")
    if classes_collection.find_one({"course_id": cls.course_id}):
        logging.warning("Duplicate course_id detected")
        raise HTTPException(status_code=400, detail="Course ID already exists")

    class_dict = cls.dict()
    result = classes_collection.insert_one(class_dict)
    class_dict["id"] = str(result.inserted_id)
    logging.info("Class created successfully")
    return class_dict

@app.post("/enrollments")
async def enroll_student(enrollment: Enrollment):
    existing = enrollments_collection.find_one({
        "student_email": enrollment.student_email,
        "course_id": enrollment.course_id
    })

    if existing:
        raise HTTPException(status_code=400, detail="Student already enrolled in this class.")

    enrollments_collection.insert_one(enrollment.dict())  # ✅ Make sure it includes username
    return {"message": "Enrollment successful"}

@app.post("/slots")
async def add_available_slot(slot: AvailableSlot):
    existing = available_slots_collection.find_one({
        "professor_email": slot.professor_email,
        "course_id": slot.course_id,
        "date": slot.date,
        "time": slot.time
    })
    if existing:
        raise HTTPException(status_code=400, detail="Slot already exists")

    available_slots_collection.insert_one(slot.dict())
    return {"message": "Slot added successfully"}

@app.get("/slots/{course_id}")
async def get_slots(course_id: str):
    slots = list(available_slots_collection.find({"course_id": course_id}))
    return [
        {
            "id": str(slot["_id"]),
            "professor_email": slot["professor_email"],
            "course_id": slot["course_id"],
            "date": slot["date"],
            "time": slot["time"]
        } for slot in slots
    ]

@app.post("/available-slots")
async def save_available_slot(slot: AvailableSlot):
    try:
        # Ensure time is in 24-hour format
        time_24 = datetime.strptime(slot.time, "%I:%M %p").strftime("%H:%M")
    except ValueError:
        time_24 = slot.time  # Already in 24-hour format

    # ❗ Updated Check: Only check professor + date + time, not course_id
    exists = available_slots_collection.find_one({
        "professor_email": slot.professor_email,
        "date": slot.date,
        "time": time_24,
    })
    if exists:
        raise HTTPException(status_code=400, detail="Slot already exists for another class")

    slot_dict = slot.dict()
    slot_dict["time"] = time_24
    available_slots_collection.insert_one(slot_dict)
    return {"message": "Slot saved successfully"}

@app.get("/available-slots")
async def get_available_slots(professor_email: str, course_id: str, date: str):
    slots = list(available_slots_collection.find({
        "professor_email": professor_email,
        "course_id": course_id,
        "date": date
    }))
    return [
        {
            "id": str(slot["_id"]),
            "time": slot["time"],
            "date": slot["date"],  # ✅ Include date for deletion logic
            "professor_email": slot["professor_email"],  # ✅ Include for reference
            "course_id": slot["course_id"]  # ✅ Include for reference
        }
        for slot in slots
    ]


@app.get("/classes", response_model=List[ClassResponse])
async def get_classes():
    classes = list(classes_collection.find())
    if not classes:
        raise HTTPException(status_code=404, detail="No classes found")
    return [{"id": str(cls["_id"]), **cls} for cls in classes]

@app.get("/classes/{course_id}", response_model=ClassResponse)
async def get_class_by_id(course_id: str):
    cls = classes_collection.find_one({"course_id": course_id})
    if not cls:
        raise HTTPException(status_code=404, detail="Class not found")
    return {"id": str(cls["_id"]), **cls}


@app.get("/appointments", response_model=List[AppointmentResponse])
async def get_appointments(student_email: str = Query(...)):
    appointments = list(appointments_collection.find({"student_email": student_email}))
    if not appointments:
        raise HTTPException(status_code=404, detail="No appointments found")

    return [
        {
            "id": str(a["_id"]),
            "student_name": a["student_name"],
            "student_email": a["student_email"],
            "course_id": a["course_id"],
            "course_name": a["course_name"],
            "professor_name": a["professor_name"],
            "appointment_date": a["appointment_date"]
        }
        for a in appointments
    ]

@app.get("/get_schedule", response_model=List[AppointmentResponse])
async def get_schedule(date: str):
    try:
        datetime.strptime(date, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    appointments = list(appointments_collection.find({"appointment_date": date}))
    if not appointments:
        raise HTTPException(status_code=404, detail="No scheduled appointments for this day")

    return [{"id": str(app["_id"]), **app} for app in appointments]

@app.get("/users/{email}")
async def get_user_by_email(email: str):
    user = users_collection.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "email": user["email"],
        "username": user["username"]
    }


@app.delete("/classes/{course_id}", response_model=dict)
async def delete_class(course_id: str):
    result = classes_collection.delete_one({"course_id": course_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Class not found")
    return {"message": "Class deleted successfully"}

@app.delete("/appointments/{appointment_id}", response_model=dict)
async def delete_appointment(appointment_id: str):
    result = appointments_collection.delete_one({"_id": ObjectId(appointment_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return {"message": "Appointment deleted successfully"}

@app.delete("/available-slots/delete")
async def delete_available_slot(professor_email: str, course_id: str, date: str, time: str):
    result = available_slots_collection.delete_one({
        "professor_email": professor_email,
        "course_id": course_id,
        "date": date,
        "time": time,
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Slot not found")
    return {"message": "Slot deleted"}

@app.delete("/available-slots")
async def delete_slot(professor_email: str, course_id: str, date: str, time: str):
    result = available_slots_collection.delete_one({
        "professor_email": professor_email,
        "course_id": course_id,
        "date": date,
        "time": time
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Slot not found")
    return {"message": "Slot deleted successfully"}

@app.get("/appointments/student/{email}")
async def get_appointments_for_student(email: str):
    student_appts = list(appointments_collection.find({"student_email": email}))

    # Get all current course_ids from the classes collection
    valid_class_ids = set(
        cls["course_id"] for cls in classes_collection.find({}, {"course_id": 1})
    )

    # Filter appointments whose course_id is still valid
    filtered = [appt for appt in student_appts if appt["course_id"] in valid_class_ids]

    # Convert ObjectId and return
    for appt in filtered:
        appt["id"] = str(appt["_id"])
        del appt["_id"]

    return filtered


@app.get("/classes/{course_id}/students")
async def get_students_for_class(course_id: str):
    enrollments = list(enrollments_collection.find({"course_id": course_id}))
    if not enrollments:
        raise HTTPException(status_code=404, detail="No students found for this class")

    return [
        {
            "email": e["student_email"],
            "username": e["student_username"]
        } for e in enrollments
    ]

@app.get("/enrollments/student/{student_email}")
async def get_enrollments_for_student(student_email: str):
    enrollments = list(enrollments_collection.find({"student_email": student_email}))
    course_ids = [e["course_id"] for e in enrollments]
    classes = list(classes_collection.find({"course_id": {"$in": course_ids}}))

    return [
        {
            "course_id": c["course_id"],
            "course_name": c["course_name"],
            "professor_name": c["professor_name"]
        } for c in classes
    ]

@app.get("/professor-email/from-course/{course_id}")
async def get_professor_email_from_course(course_id: str):
    cls = classes_collection.find_one({"course_id": course_id})
    if not cls:
        raise HTTPException(status_code=404, detail="Class not found")

    professor_username = cls.get("professor_name")
    if not professor_username:
        raise HTTPException(status_code=404, detail="Professor name missing in class")

    user = users_collection.find_one({"username": professor_username})
    if not user or "email" not in user:
        raise HTTPException(status_code=404, detail="Professor email not found")

    return {"email": user["email"]}

@app.get("/users/username/{username}")
async def get_user_by_username(username: str):
    user = users_collection.find_one({"username": username})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "email": user["email"],
        "username": user["username"]
    }

@app.delete("/appointments/{appointment_id}", response_model=dict)
async def cancel_appointment(appointment_id: str):
    try:
        # Fetch appointment before deletion
        appointment = appointments_collection.find_one({"_id": ObjectId(appointment_id)})
        if not appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")

        # Parse date/time from ISO format
        appointment_datetime = datetime.fromisoformat(appointment["appointment_date"])
        date_str = appointment_datetime.strftime("%Y-%m-%d")
        time_str = appointment_datetime.strftime("%H:%M")

        # Restore the slot to available_slots
        slot = {
            "professor_email": appointment["professor_email"],
            "course_id": appointment["course_id"],
            "date": date_str,
            "time": time_str
        }
        available_slots_collection.insert_one(slot)

        notifications_collection.insert_one({
            "recipient_email": appointment["student_email"],
            "title": "❌ Appointment Cancelled",
            "message": f"Your appointment for {appointment['course_name']} at {appointment_datetime.strftime('%b %d %I:%M %p')} was cancelled.",
            "type": "cancellation",
            "timestamp": datetime.utcnow(),
            "read": False
        })

        # Delete the appointment
        result = appointments_collection.delete_one({"_id": ObjectId(appointment_id)})
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Appointment could not be deleted")

        return {"message": "Appointment cancelled and slot restored"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@app.get("/appointments/professor/{course_id}")
async def get_appointments_for_professor(course_id: str):
    appts = list(appointments_collection.find({"course_id": course_id}))
    for a in appts:
        a["id"] = str(a["_id"])
        del a["_id"]
    return appts

@app.post("/appointments/{appointment_id}/reschedule", response_model=dict)
async def reschedule_appointment(
    appointment_id: str,
    new_datetime: str = Body(...),
    course_id: str = Body(...),
    student_email: str = Body(...)
):
    try:
        new_dt = datetime.fromisoformat(new_datetime)

        # Optional: check if student already booked the new slot

        result = appointments_collection.update_one(
            {"_id": ObjectId(appointment_id)},
            {"$set": {"appointment_date": new_dt.isoformat()}}
        )

        if result.modified_count == 0:
            raise HTTPException(status_code=400, detail="Appointment not updated")
        
        old_appt = appointments_collection.find_one({"_id": ObjectId(appointment_id)})
        notifications_collection.insert_one({
            "recipient_email": student_email,
            "title": "📆 Appointment Rescheduled",
            "message": f"Your appointment for {old_appt['course_name']} was rescheduled to {new_dt.strftime('%Y-%m-%d %I:%M %p')}.",
            "type": "reschedule",
            "timestamp": datetime.utcnow(),
            "read": False
        })
    
        return {"message": "Appointment rescheduled"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    


@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_text()
            logging.info(f"📩 Message from {user_id}: {data}")
            # Example: Echo message back to sender (can enhance later)
            await manager.send_personal_message(f"You said: {data}", user_id)
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)

connected_users: Dict[str, WebSocket] = {}

@app.websocket("/ws/chat/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await websocket.accept()
    connected_users[user_id] = websocket
    try:
        while True:
            data = await websocket.receive_json()
            # Save to MongoDB
            chat_messages_collection.insert_one({
                "sender_id": data["sender_id"],
                "receiver_id": data["receiver_id"],
                "message": data["message"],
                "timestamp": datetime.utcnow().isoformat()
            })

            # Forward message to recipient if connected
            receiver_ws = connected_users.get(data["receiver_id"])
            if receiver_ws:
                await receiver_ws.send_json(data)
    except WebSocketDisconnect:
        connected_users.pop(user_id, None)

@app.get("/chat/history")
def get_chat_history(user1: str, user2: str):
    messages = list(chat_messages_collection.find({
        "$or": [
            {"sender_id": user1, "receiver_id": user2},
            {"sender_id": user2, "receiver_id": user1},
        ]
    }).sort("timestamp", 1))

    for msg in messages:
        msg["id"] = str(msg["_id"])
        del msg["_id"]
    return messages

@app.get("/notifications/{email}")
async def get_notifications(email: str):
    raw_notifications = notifications_collection.find({"recipient_email": email}).sort("timestamp", -1)
    
    notifications = []
    for n in raw_notifications:
        n["_id"] = str(n["_id"])  # Convert ObjectId to string
        notifications.append(n)
    
    return notifications


@app.post("/notifications/{notification_id}/mark-read")
async def mark_notification_as_read(notification_id: str):
    result = notifications_collection.update_one(
        {"_id": ObjectId(notification_id)},
        {"$set": {"read": True}}
    )
    if result.modified_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"message": "Notification marked as read"}
