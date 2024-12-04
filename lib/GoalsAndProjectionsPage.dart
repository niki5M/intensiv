import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:google_fonts/google_fonts.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<DocumentSnapshot> reminders = [];
  String userId = '';
  bool isLoading = true;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _initNotifications();
  }

  // Инициализация уведомлений
  void _initNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones(); // Инициализация часовых поясов
  }

  // Создание уведомления
  Future<void> _scheduleNotification(
      String title, String body, DateTime date) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('reminder_channel', 'Напоминания',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true);
    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(date, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Получаем текущий userId
  void _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _fetchReminders();
    }
  }

  // Загрузка данных из Firestore
  void _fetchReminders() async {
    if (userId.isEmpty) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reminders')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        reminders = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorMessage('Ошибка загрузки данных: $e');
    }
  }

  // Добавление нового напоминания
  void _addReminder() {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Добавить напоминание"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Название"),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: "Сумма"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                  },
                  child: const Text("Выбрать дату"),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                  },
                  child: const Text("Выбрать время"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    amountController.text.isNotEmpty &&
                    selectedDate != null &&
                    selectedTime != null) {
                  final notificationDate = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );

                  final newReminder = {
                    'title': titleController.text.trim(),
                    'amount': double.parse(amountController.text.trim()),
                    'date': notificationDate,
                    'userId': userId,
                    'isPaid': false,
                    'notificationsEnabled': true,
                  };

                  await FirebaseFirestore.instance
                      .collection('reminders')
                      .add(newReminder);
                  _fetchReminders();
                  _scheduleNotification(
                      "Напоминание",
                      "Пора оплатить: ${titleController.text}",
                      notificationDate);
                  Navigator.pop(context);
                } else {
                  _showErrorMessage("Заполните все поля");
                }
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  // Обновление статуса оплаты или уведомлений
  void _toggleStatus(DocumentSnapshot reminder, String field) async {
    try {
      final currentValue = reminder[field];
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(reminder.id)
          .update({field: !currentValue});
      _fetchReminders();
    } catch (e) {
      _showErrorMessage('Ошибка обновления: $e');
    }
  }

  // Показ сообщения об ошибке
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Напоминания',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addReminder,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
          ? const Center(child: Text("Напоминаний нет"))
          : Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A), // Цвет фона контейнера
            borderRadius: BorderRadius.circular(30), // Закругленные углы
          ),
          child: ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final data = reminders[index].data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0), // Отступы справа и слева
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800], // Серый фон для карточки
                    borderRadius: BorderRadius.circular(20), // Закругленные углы
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5), // Тень справа
                        offset: const Offset(5, 5), // Сдвиг тени
                        blurRadius: 10, // Размытие тени
                        spreadRadius: 2, // Расстояние распространения тени
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF1A1A1A), // Цвет фона контейнера
                      ),
                      child: ListTile(
                        title: Text(
                          data['title'] ?? "Без названия",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Сумма: ${data['amount']}", style: const TextStyle(color: Colors.white)),
                            Text("Дата: ${(data['date'] as Timestamp).toDate()}", style: const TextStyle(color: Colors.white)),
                            Row(
                              children: [
                                Text(
                                  data['isPaid'] ? "Статус: Оплачено" : "Статус: Не оплачено",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: GestureDetector(
                          onTap: () => _toggleStatus(reminders[index], 'isPaid'),
                          child: Container(
                            width: 44, // Ширина контейнера
                            height: 44, // Высота контейнера
                            decoration: BoxDecoration(
                              color: Colors.grey[850], // Серый фон
                              shape: BoxShape.circle, // Круглая форма
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.6), // Тень
                                  blurRadius: 8, // Размытие тени
                                  offset: const Offset(0, 4), // Смещение тени
                                ),
                              ],
                            ),
                            child: Icon(
                              data['isPaid'] ? Icons.check_circle : Icons.circle_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );

            },
          ),
        ),
      ),
    );
  }

}
