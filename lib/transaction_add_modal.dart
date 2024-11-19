import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionAddModal extends StatefulWidget {
  final Map<String, dynamic>? selectedAccount;
  final Function(Map<String, dynamic>) onTransactionAdded;

  const TransactionAddModal({
    Key? key,
    required this.selectedAccount,
    required this.onTransactionAdded,
  }) : super(key: key);

  @override
  _TransactionAddModalState createState() => _TransactionAddModalState();
}

class _TransactionAddModalState extends State<TransactionAddModal> {
  final TextEditingController amountController = TextEditingController();
  String? selectedTransactionType;
  String? selectedSubcategory;

  List<String> incomeSubcategories = ['Зарплата', 'Доп. доход'];
  List<String> expenseSubcategories = ['Продукты', 'Транспорт', 'Развлечения'];

  Future<void> _addTransaction() async {
    if (widget.selectedAccount == null ||
        amountController.text.isEmpty ||
        selectedTransactionType == null ||
        selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля.')),
      );
      return;
    }

    final newTransaction = {
      'accountId': widget.selectedAccount!['id'],
      'amount': double.parse(amountController.text),
      'category': selectedSubcategory,
      'transactionType': selectedTransactionType,
      'date': DateTime.now(),
    };

    try {
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('transactions')
          .add(newTransaction);

      widget.onTransactionAdded({
        'id': docRef.id,
        ...newTransaction,
      });

      Navigator.of(context).pop();
    } catch (e) {
      print('Ошибка добавления транзакции: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка добавления транзакции.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Сумма'),
          ),
          DropdownButton<String>(
            value: selectedTransactionType,
            onChanged: (newValue) {
              setState(() {
                selectedTransactionType = newValue;
              });
            },
            hint: const Text('Выберите тип транзакции'),
            items: ['Доход', 'Расход'].map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
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
            hint: const Text('Выберите категорию'),
            items: (selectedTransactionType == 'Доход'
                ? incomeSubcategories
                : expenseSubcategories)
                .map((category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addTransaction,
            child: const Text('Добавить транзакцию'),
          ),
        ],
      ),
    );
  }
}