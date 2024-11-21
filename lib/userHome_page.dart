import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserAccountsPage extends StatefulWidget {
  const UserAccountsPage({Key? key}) : super(key: key);

  @override
  _UserAccountsPageState createState() => _UserAccountsPageState();
}

class _UserAccountsPageState extends State<UserAccountsPage> {
  List<Map<String, dynamic>> accounts = [];
  Map<String, dynamic>? selectedAccount;
  List<Map<String, dynamic>> localTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadTransactions();
  }

  Future<void> _loadAccounts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('bankAccounts')
            .where('userId', isEqualTo: user.uid)
            .get();

        setState(() {
          accounts = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'accountType': doc['accountType'],
              'balance': doc['balance'],
            };
          }).toList();
        });

        if (accounts.isNotEmpty) {
          setState(() {
            selectedAccount = accounts[0];
          });
        }
      } catch (e) {
        print('Error loading accounts: $e');
      }
    }
  }

  Future<void> _loadTransactions() async {
    if (selectedAccount == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('accountId', isEqualTo: selectedAccount!['id'])
          .orderBy('date', descending: true)
          .get();

      setState(() {
        localTransactions = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _addTransaction(Map<String, dynamic> newTransaction) async {
    if (selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Выберите счёт для добавления транзакции.')),
      );
      return;
    }

    try {
      // Добавляем транзакцию
      DocumentReference docRef =
      await FirebaseFirestore.instance.collection('transactions').add(
          newTransaction);

      // Обновляем локальные данные
      setState(() {
        localTransactions.insert(0, {
          'id': docRef.id,
          ...newTransaction,
        });
      });

      // Обновляем баланс счета в зависимости от типа транзакции
      double newBalance = selectedAccount!['balance'];
      if (newTransaction['transactionType'] == 'Расход') {
        newBalance -= newTransaction['amount']; // Вычитаем при расходе
      } else if (newTransaction['transactionType'] == 'Доход') {
        newBalance += newTransaction['amount']; // Добавляем при доходе
      }

      // Обновляем счет в Firestore с новым балансом
      await FirebaseFirestore.instance
          .collection('bankAccounts')
          .doc(selectedAccount!['id'])
          .update({'balance': newBalance});

      // Обновляем локальные данные с новым балансом
      setState(() {
        selectedAccount!['balance'] = newBalance;
      });
    } catch (e) {
      print('Ошибка добавления транзакции: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ошибка добавления транзакции. Попробуйте снова.')),
      );
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      await FirebaseFirestore.instance.collection('transactions').doc(
          transactionId).delete();

      setState(() {
        localTransactions.removeWhere((tx) => tx['id'] == transactionId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Транзакция удалена.')),
      );
    } catch (e) {
      print('Ошибка при удалении транзакции: $e');
    }
  }

  // Модальное окно для добавления транзакции
  Future<void> _showAddTransactionModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF2C2F33), // Задаём цвет фона для всего модального окна
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return AddTransactionModal(
          onTransactionAdded: _addTransaction,
          selectedAccount: selectedAccount,
        );
      },
    );
  }

  // Метод для удаления счёта и связанных с ним транзакций
  Future<void> _deleteAccount(String accountId) async {
    try {
      // Сначала удалим все транзакции, связанные с этим счётом
      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('accountId', isEqualTo: accountId)
          .get();

      for (var doc in transactionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Теперь удалим сам счёт
      await FirebaseFirestore.instance.collection('bankAccounts')
          .doc(accountId)
          .delete();

      // Обновим локальные данные
      setState(() {
        accounts.removeWhere((account) => account['id'] == accountId);
        if (accounts.isNotEmpty) {
          selectedAccount = accounts[0];
        } else {
          selectedAccount = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Счёт и все связанные транзакции удалены.')),
      );
    } catch (e) {
      print('Ошибка при удалении счёта: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при удалении счёта.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(

        children: [
          // Верхняя часть экрана с фоном
          Expanded(
            flex: 2, // Это фактически 1.5 от 4
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF060808), Color(0xFF0A0A0A)],
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 26.0, top: 45.00),
                      child: const Text(
                        'SpendWise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: accounts.isEmpty
                        ? const Text(
                      'Счета не найдены',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                        : PageView.builder(
                      controller: PageController(viewportFraction: 0.9),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedAccount = account),
                          onLongPress: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Удалить счёт'),
                                  content: const Text(
                                      'Вы уверены, что хотите удалить этот счёт?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (shouldDelete == true) {
                              await _deleteAccount(account['id']);
                            }
                          },
                          child: _buildBankCard(account),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Транзакции',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showAddTransactionModal,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF717171) , backgroundColor: const Color(
                            0xFF000000), // Цвет текста кнопки
                        ),
                        child: const Text('Добавить'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 0),
                  Expanded(
                    child: ListView.builder(

                      itemCount: localTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = localTransactions[index];
                        return ListTile(
                          leading: transaction['transactionType'] == 'Расход'
                              ? const Icon(
                              Icons.money_off, color: Color(0xFF6E0534), size: 30)
                              : const Icon(
                              Icons.attach_money, color: Color(0xFF166778), size: 30),
                          title: Text(
                            '${transaction['category']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 21,
                            ),
                          ),
                          subtitle: Text(
                            '${transaction['transactionType']}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 18,
                            ),
                          ),
                          trailing: Text(
                            '₽${transaction['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: transaction['transactionType'] == 'Расход'
                                  ? const Color(0xFF8E0844) // Красный для расхода
                                  : const Color(0xFF26E6E6), // Голубой для дохода
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> account) {
    return Container(
      margin: const EdgeInsets.only(
          left: 15.0, right: 15.0, top: 110.0, bottom: 35.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF202020), Color(0xFF070707)], // Градиент от темного к светлому
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6), // Более насыщенная тень для объема
            blurRadius: 12, // Увеличенная размытие для большего эффекта
            offset: const Offset(-4, -4), // Смещение тени для объема
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1), // Светлая тень для дополнительного объема
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account['accountType'],
              style: const TextStyle(fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 50),
            Text(
              '${account['balance'].toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70, fontSize: 25,  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTransactionModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onTransactionAdded;
  final Map<String, dynamic>? selectedAccount;

  const AddTransactionModal({Key? key, required this.onTransactionAdded, this.selectedAccount}) : super(key: key);

  @override
  _AddTransactionModalState createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final amountController = TextEditingController();
  String? selectedTransactionType;
  String? selectedSubcategory;
  final List<String> incomeSubcategories = ['Зарплата', 'Подарки', 'Продажа'];
  final List<String> expenseSubcategories = ['Еда', 'Транспорт', 'Развлечения'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Container(
        color: Color(0xFF2C2F33), // Темный фон
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Сумма',
                labelStyle: TextStyle(color: Colors.white), // Белый текст для метки
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Белая линия
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Белая линия при фокусе
                ),
              ),
              style: TextStyle(color: Colors.white), // Белый текст
            ),
            DropdownButton<String>(
              value: selectedTransactionType,
              onChanged: (newValue) {
                setState(() {
                  selectedTransactionType = newValue;
                });
              },
              hint: Text('Выберите тип транзакции', style: TextStyle(color: Colors.white)),
              dropdownColor: Color(0xFF2C2F33), // Темный фон выпадающего меню
              items: ['Доход', 'Расход'].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              value: selectedSubcategory,
              onChanged: (newValue) {
                setState(() {
                  selectedSubcategory = newValue;
                });
              },
              hint: Text('Выберите категорию', style: TextStyle(color: Colors.white)),
              dropdownColor: Color(0xFF2C2F33), // Темный фон выпадающего меню
              items: (selectedTransactionType == 'Доход'
                  ? incomeSubcategories
                  : expenseSubcategories)
                  .map((category) => DropdownMenuItem<String>(
                value: category,
                child: Text(category, style: TextStyle(color: Colors.white)),
              ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isEmpty ||
                    selectedTransactionType == null ||
                    selectedSubcategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все поля для добавления транзакции.')),
                  );
                  return;
                }

                final newTransaction = {
                  'accountId': widget.selectedAccount!['id'],
                  'amount': double.parse(amountController.text),
                  'category': selectedSubcategory,
                  'transactionType': selectedTransactionType,
                  'description': 'Только что добавлена',
                  'date': DateTime.now(),
                };

                widget.onTransactionAdded(newTransaction);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Color(0xFF333333), // Белый текст
              ),
              child: const Text('Добавить транзакцию'),
            ),
          ],
        ),
      ),
    );
  }
}