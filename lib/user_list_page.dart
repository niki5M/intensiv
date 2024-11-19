import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({Key? key}) : super(key: key);

  @override
  _AllTransactionsPageState createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все транзакции'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Транзакции отсутствуют.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transactionData = transactions[index].data() as Map<String, dynamic>;
              final transactionId = transactions[index].id;
              final accountId = transactionData['accountId'] ?? 'Неизвестный счет';
              final transactionType = transactionData['transactionType'] ?? 'Неизвестно';
              final amount = transactionData['amount'] ?? 0.0;
              final category = transactionData['category'] ?? 'Не указана';
              final description = transactionData['description'] ?? 'Нет описания';
              final rawDate = transactionData['date'];
              String formattedDate;

              if (rawDate is Timestamp) {
                final date = rawDate.toDate();
                formattedDate = '${date.day}.${date.month}.${date.year}';
              } else {
                formattedDate = 'Неизвестная дата';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: transactionType == 'expense'
                        ? const Icon(Icons.money_off, color: Colors.red)
                        : const Icon(Icons.attach_money, color: Colors.green),
                    title: Text(
                      '₽${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Счёт: $accountId',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          'Категория: $category',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          'Описание: $description',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Дата: $formattedDate',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white70),
                      onPressed: () => _deleteTransaction(transactionId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      await FirebaseFirestore.instance.collection('transactions').doc(transactionId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Транзакция удалена.')),
      );
    } catch (e) {
      print('Ошибка при удалении транзакции: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при удалении транзакции.')),
      );
    }
  }
}
