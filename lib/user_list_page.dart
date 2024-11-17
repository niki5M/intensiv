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
        backgroundColor: Colors.black, // Темный фон для AppBar
        elevation: 0, // Убираем тень
      ),
      backgroundColor: Colors.black, // Темный фон страницы
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bankAccounts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Нет пользователей.', style: TextStyle(color: Colors.white)));
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
                    key: Key(userId),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      color: const Color(0xFF57001F), // Цвет фона при свайпе
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
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
                      _deleteUserAccount(userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$ownerName удалён')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                      child: Container(
                        padding: const EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E1E1E), // Темная карточка
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selectedUserId == userId) {
                                selectedUserId = null;
                              } else {
                                selectedUserId = userId;
                              }
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Баланс: \$${balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
                            return const Center(
                              child: Text('Нет транзакций для данного счёта.',
                                  style: TextStyle(color: Colors.white)),
                            );
                          }

                          final transactions = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transactionData = transactions[index].data() as Map<String, dynamic>;
                              final transactionType = transactionData['type'] ?? 'Неизвестно';
                              final amount = transactionData['amount'] ?? 0.0;
                              final category = transactionData['category'] ?? 'Неизвестно';
                              final description = transactionData['description'] ?? 'Нет описания';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5.0),
                                child: ListTile(
                                  tileColor: const Color(0xFF2A2A2A), // Темный фон для транзакции
                                  leading: transactionType == 'expense'
                                      ? const Icon(Icons.money_off, color: Colors.red)
                                      : const Icon(Icons.attach_money, color: Colors.green),
                                  title: Text('\$${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(
                                    'Категория: $category\nОписание: $description',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
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