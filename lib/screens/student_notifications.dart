import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetme/api_service.dart';

class StudentNotificationsPage extends StatefulWidget {
  const StudentNotificationsPage({super.key});

  @override
  State<StudentNotificationsPage> createState() =>
      _StudentNotificationsPageState();
}

class _StudentNotificationsPageState extends State<StudentNotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  String? studentEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    final info = await ApiService.getUserInfo();
    studentEmail = info['email'];

    if (studentEmail != null) {
      final fetched = await ApiService.getNotifications();
      setState(() {
        notifications = fetched;
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    await ApiService.markNotificationAsRead(id);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(child: Text("No notifications yet."))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final dt = DateTime.tryParse(n['timestamp'] ?? '');
                      final formatted = dt != null
                          ? DateFormat.yMMMd().add_jm().format(dt)
                          : '';
                      return ListTile(
                        title: Text(n['title'] ?? '',
                            style: TextStyle(
                                fontWeight: n['read'] == true
                                    ? FontWeight.normal
                                    : FontWeight.bold)),
                        subtitle: Text("${n['message'] ?? ''}\n$formatted"),
                        isThreeLine: true,
                        trailing: n['read'] == true
                            ? null
                            : TextButton(
                                onPressed: () => _markAsRead(n['_id']),
                                child: const Text("Mark Read"),
                              ),
                      );
                    },
                  ),
      ),
    );
  }
}
