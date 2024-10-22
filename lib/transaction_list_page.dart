import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionListPage extends StatelessWidget {
  final String accountId;

  const TransactionListPage({Key? key, required this.accountId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакции'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bankAccounts')
            .doc(accountId)
            .collection('transactions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет транзакций для данного счёта.'));
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transactionData = transactions[index].data() as Map<String, dynamic>;
              final transactionType = transactionData['type'] ?? 'Неизвестно';
              final amount = transactionData['amount'] ?? 0.0;
              final category = transactionData['category'] ?? 'Неизвестно';
              final description = transactionData['description'] ?? 'Нет описания';

              return ListTile(
                title: Text('$transactionType: $amount'),
                subtitle: Text('Категория: $category\nОписание: $description'),
              );
            },
          );
        },
      ),
    );
  }
}
