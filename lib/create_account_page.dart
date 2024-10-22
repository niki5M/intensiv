import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  Future<void> _createAccount() async {
    String ownerName = _ownerNameController.text.trim();
    double balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;

    if (ownerName.isNotEmpty) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('bankAccounts').add({
            'ownerName': ownerName,
            'balance': balance,
            'accountId': user.uid, // Привязываем счет к пользователю
          });

          Navigator.pop(context); // Закрываем страницу создания счета
        } catch (e) {
          print('Ошибка при создании счета: $e');
          // Здесь можно добавить обработку ошибок
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать новый счет'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ownerNameController,
              decoration: const InputDecoration(labelText: 'Имя владельца счета'),
            ),
            TextField(
              controller: _balanceController,
              decoration: const InputDecoration(labelText: 'Баланс'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createAccount,
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}