# models.py
from pydantic import BaseModel, EmailStr, Field, constr
from datetime import datetime
from typing import Any, Optional
from typing import Annotated
from pydantic import StringConstraints

class User(BaseModel):
    """Model representing a user."""
    email: EmailStr
    username: Annotated[str, StringConstraints(min_length=5, max_length=20)]
    password: Annotated[str, StringConstraints(min_length=4)]
    role: Annotated[str, StringConstraints(pattern="^(student|professor)$")]

class UserResponse(BaseModel):
    """Model for user response without password."""
    email: EmailStr
    username: str
    role: str

class Appointment(BaseModel):
    """Model representing an appointment."""
    student_name: str
    student_email: EmailStr
    course_id: str
    course_name: str
    professor_name: str
    appointment_date: datetime

class AppointmentResponse(Appointment):
    """Model for appointment response with an ID."""
    id: str

class Class(BaseModel):
    """Model representing a class."""
    course_id: str
    course_name: str
    professor_name: str
    professor_email: Optional[EmailStr] = None
    description: str = "" 

class ClassResponse(Class):
    """Model for class response with an ID."""
    id: str

class LoginModel(BaseModel):
    email: str
    password: str



class Enrollment(BaseModel):
    student_email: EmailStr
    student_username: str
    course_id: str

class Config:
    allow_population_by_field_name = True  # ✅ allows using camelCase in your app 

class AvailableSlot(BaseModel):
    professor_email: EmailStr
    course_id: str
    date: str  # Format: YYYY-MM-DD
    time: str  # Format: HH:MM (24-hour)

class Notification(BaseModel):
    recipient_email: str
    title: str
    message: str
    type: str  # "booking" or "reschedule"
    timestamp: datetime = datetime.utcnow()
    read: bool = False