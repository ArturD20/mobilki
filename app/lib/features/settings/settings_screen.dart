import 'package:flutter/material.dart';
import '../../core/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _applyNotificationSettings();
  }

  void _applyNotificationSettings() async {
    if (notificationsEnabled) {
      await NotificationService.scheduleDailyNotification(time: notificationTime);
    } else {
      await NotificationService.cancelAllNotifications();
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: notificationTime,
    );
    if (picked != null) {
      setState(() => notificationTime = picked);
      _applyNotificationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Powiadomienia', style: TextStyle(fontSize: 18)),
                Switch(
                  value: notificationsEnabled,
                  onChanged: (v) {
                    setState(() => notificationsEnabled = v);
                    _applyNotificationSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Wybierz godzinę powiadomień:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: notificationsEnabled ? _pickTime : null,
              child: AbsorbPointer(
                absorbing: !notificationsEnabled,
                child: Container(
                  decoration: BoxDecoration(
                    color: notificationsEnabled ? Colors.white : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${notificationTime.format(context)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: notificationsEnabled ? Colors.black : Colors.grey,
                        ),
                      ),
                      Icon(Icons.access_time, color: notificationsEnabled ? Colors.black : Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!notificationsEnabled)
              Text('Aby ustawić godzinę, włącz powiadomienia.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
