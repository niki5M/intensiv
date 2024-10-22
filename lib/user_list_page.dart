import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String? selectedUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список пользователей'),
        backgroundColor: Colors.white, // Цвет заголовка
      ),
      backgroundColor: Colors.black, // Почти черный фон страницы
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bankAccounts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет пользователей.', style: TextStyle(color: Colors.white)));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final ownerName = userData['ownerName'] ?? 'Неизвестно';
              final balance = userData['balance'] ?? 0.0;

              return Column(
                children: [
                  Dismissible(
                    key: Key(userId), // Уникальный ключ для каждой карточки
                    direction: DismissDirection.startToEnd, // Свайп влево
                    background: Container(
                      color: const Color(0xFF57001F), // Цвет фона при свайпе
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white), // Иконка удаления
                    ),
                    confirmDismiss: (direction) async {
                      // Подтверждение удаления
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Подтверждение удаления'),
                            content: const Text('Вы уверены, что хотите удалить этот счет?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Удалить'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      // Удаляем из Firestore
                      _deleteUserAccount(userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$ownerName удалён')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                      child: Center( // Центрируем карточки
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.85, // Ширина карточки
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white, // Цвет карточки
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: GestureDetector( // Используем GestureDetector для обработки нажатий
                            onTap: () {
                              setState(() {
                                // Меняем выбранного пользователя
                                if (selectedUserId == userId) {
                                  selectedUserId = null; // Скрываем транзакции, если уже выбраны
                                } else {
                                  selectedUserId = userId; // Устанавливаем выбранного пользователя
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ownerName,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Баланс: \$${balance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.black26,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Отображаем транзакции только для выбранного пользователя
                  if (selectedUserId == userId) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bankAccounts')
                            .doc(userId)
                            .collection('transactions')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('Нет транзакций для данного счёта.', style: TextStyle(color: Colors.white)));
                          }

                          final transactions = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true, // Чтобы использовать минимальное пространство
                            physics: const NeverScrollableScrollPhysics(), // Отключаем прокрутку в этом списке
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transactionData = transactions[index].data() as Map<String, dynamic>;
                              final transactionType = transactionData['type'] ?? 'Неизвестно';
                              final amount = transactionData['amount'] ?? 0.0;
                              final category = transactionData['category'] ?? 'Неизвестно';
                              final description = transactionData['description'] ?? 'Нет описания';

                              return ListTile(
                                leading: transactionType == 'expense'
                                    ? const Icon(Icons.money_off, color: Colors.red) // Иконка расхода
                                    : const Icon(Icons.attach_money, color: Colors.green), // Иконка дохода
                                title: Text(' \$${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Категория: $category\nОписание: $description', style: const TextStyle(color: Colors.white70, fontSize: 8)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteUserAccount(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('bankAccounts').doc(userId).delete();
    } catch (e) {
      print('Ошибка при удалении счета: $e');
    }
  }
}
