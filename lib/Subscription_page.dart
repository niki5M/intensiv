import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool isPurchasing = false;
  bool purchaseSuccess = false;
  bool hasPremiumAccess = false; // Флаг для отслеживания подписки
  String selectedSubscription = ''; // Переменная для выбранного типа подписки

  // Симуляция процесса покупки
  Future<void> _simulatePurchase() async {
    setState(() {
      isPurchasing = true; // Показать индикатор загрузки
    });

    // Имитация задержки на процесс покупки (например, API запрос)
    await Future.delayed(const Duration(seconds: 3));

    // Определяем дату окончания подписки в зависимости от типа
    DateTime now = DateTime.now();
    DateTime endDate;

    if (selectedSubscription == 'month') {
      endDate = now.add(Duration(days: 30)); // 30 дней от текущей даты
    } else if (selectedSubscription == 'year') {
      endDate = now.add(Duration(days: 365)); // 1 год от текущей даты
    } else {
      return; // Неверный тип подписки
    }

    // Получаем текущего пользователя
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Если пользователь не авторизован
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка! Пользователь не авторизован.')),
      );
      return;
    }

    // Сохраняем дату окончания подписки в Firestore
    try {
      // Обновляем или создаем документ с UID текущего пользователя в коллекции "customers"
      await FirebaseFirestore.instance.collection('customers').doc(user.uid).set({
        'subscription_end_date': endDate.toIso8601String(),
      }, SetOptions(merge: true)); // Используем merge: true для обновления или создания документа

      setState(() {
        isPurchasing = false; // Скрыть индикатор загрузки
        purchaseSuccess = true; // Успешная покупка
        hasPremiumAccess = true; // Доступ к премиум функциям
      });

      // Покажем сообщение об успешной покупке
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Подписка успешно оформлена!')),
      );
    } catch (e) {
      setState(() {
        isPurchasing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }


  // Метод для выбора подписки
  void _selectSubscription(String type) {
    setState(() {
      selectedSubscription = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Черный фон
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Крестик для возврата на предыдущую страницу
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pop(context); // Возврат на предыдущую страницу
                },
              ),
            ),
            // Большая иконка подписки посередине
            Center(
              child: Image.asset(
                'assets/images/premium.png', // Здесь указывайте путь к вашей иконке
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 0),

            // Заголовок
            const Text(
              'Premium Подписка',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Получите доступ ко всем эксклюзивным функциям, ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 32),

            // Карточки для выбора подписки
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Карточка для подписки на месяц
                SubscriptionCard(
                  title: 'Месяц',
                  price: '299₽',
                  isSelected: selectedSubscription == 'month',
                  onTap: () => _selectSubscription('month'),
                ),
                const SizedBox(width: 16),
                // Карточка для подписки на год
                SubscriptionCard(
                  title: 'Год',
                  price: '2999₽',
                  isSelected: selectedSubscription == 'year',
                  onTap: () => _selectSubscription('year'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Кнопка для оформления подписки
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF01005F), Color(0xFF5C44EC)], // Задайте цвета для градиента
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30), // Углы кнопки
              ),
              child: ElevatedButton(
                onPressed: isPurchasing || selectedSubscription.isEmpty
                    ? null
                    : _simulatePurchase,
                child: isPurchasing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Оформить подписку'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16), backgroundColor: Colors.transparent, // Сделать фон кнопки прозрачным
                  elevation: 0, // Убрать тень, так как она не нужна
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const SubscriptionCard({
    required this.title,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected ? Color(0xFF181B7B) : Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
