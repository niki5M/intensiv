import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Для использования groupBy

class UserAccountsPage extends StatefulWidget {
  const UserAccountsPage({Key? key}) : super(key: key);

  @override
  _UserAccountsPageState createState() => _UserAccountsPageState();
}

class _UserAccountsPageState extends State<UserAccountsPage> {
  List<Map<String, dynamic>> accounts = [];
  bool isLoading = true;
  Map<String, dynamic>? selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('bankAccounts')
            .where('userId', isEqualTo: user.uid)
            .get();

        List<Map<String, dynamic>> fetchedAccounts = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'accountType': doc['accountType'],
            'balance': doc['balance'],
          };
        }).toList();

        if (fetchedAccounts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('У вас нет счетов. Добавьте новый счёт.')),
          );
        }

        setState(() {
          accounts = fetchedAccounts;
          isLoading = false;
        });
      } catch (e) {
        print('Error loading accounts: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки счетов. Попробуйте снова.')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : accounts.isEmpty
          ? const Center(
        child: Text(
          'Счета не найдены.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060808), Color(0xFF053641)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: accounts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == accounts.length) {
                        return _buildAddAccountButton();
                      } else {
                        final account = accounts[index];
                        return _buildBankCard(account);
                      }
                    },
                  ),
                ),
              ),
              if (selectedAccount != null) ...[
                _buildAddTransactionButton(),
                _buildTransactionChart(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: GestureDetector(
        onTap: () {
          _showAccountDetails(account);
        },
        child: Container(
          width: 350,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 12.0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account['accountType'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'EXP: 12/24',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${account['balance'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddAccountButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          _showCreateAccountDialog();
        },
        child: Container(
          width: 50,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.black.withOpacity(0.8),
          ),
          child: Center(
            child: const Text(
              '+ ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountDetails(Map<String, dynamic> account) {
    setState(() {
      selectedAccount = account;
    });
  }

  Widget _buildAddTransactionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ElevatedButton(
        onPressed: () {
          _showAddTransactionDialog();
        },
        child: const Text(
          'Добавить транзакцию',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Future<void> _showAddTransactionDialog() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить транзакцию'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                ),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                final category = categoryController.text;

                if (amount > 0 && category.isNotEmpty && selectedAccount != null) {
                  await _addNewTransaction(amount, category);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все поля корректно.')),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewTransaction(double amount, String category) async {
    try {
      if (selectedAccount != null) {
        await FirebaseFirestore.instance.collection('transactions').add({
          'accountId': selectedAccount!['id'],
          'amount': amount,
          'category': category,
          'date': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Транзакция добавлена')),
        );
        setState(() {});
      }
    } catch (e) {
      print('Error adding transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка добавления транзакции.')),
      );
    }
  }

  Widget _buildTransactionChart() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('transactions')
          .where('accountId', isEqualTo: selectedAccount!['id'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Нет транзакций.'));
        }

        final transactions = snapshot.data!.docs.map((doc) {
          return {
            'amount': doc['amount'],
            'category': doc['category'],
          };
        }).toList();

        final groupedTransactions = groupBy(transactions, (transaction) => transaction['category']);

        final categories = groupedTransactions.keys.toList();
        final amounts = groupedTransactions.values.map((list) {
          return list.fold(0.0, (sum, item) => sum + item['amount']);
        }).toList();

        return PieChart(
          PieChartData(
            sections: List.generate(categories.length, (index) {
              return PieChartSectionData(
                value: amounts[index],
                title: categories[index],
                color: Colors.primaries[index % Colors.primaries.length],
                radius: 50,
                titleStyle: const TextStyle(color: Colors.white),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> _showCreateAccountDialog() async {
    final TextEditingController accountTypeController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать новый счёт'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: accountTypeController,
                decoration: const InputDecoration(
                  labelText: 'Тип счёта',
                ),
              ),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Баланс',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final accountType = accountTypeController.text;
                final balance = double.tryParse(balanceController.text) ?? 0.0;

                if (accountType.isNotEmpty && balance >= 0) {
                  await _createNewAccount(accountType, balance);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все поля корректно.')),
                  );
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewAccount(String accountType, double balance) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('bankAccounts').add({
          'userId': user.uid,
          'accountType': accountType,
          'balance': balance,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Новый счёт добавлен.')),
        );
        setState(() {
          _loadAccounts(); // Обновление списка счётов
        });
      }
    } catch (e) {
      print('Error creating account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка создания счёта.')),
      );
    }
  }
}
