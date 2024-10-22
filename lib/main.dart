import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intensiv_wise/login_page.dart';
import 'package:intensiv_wise/profile.dart';
import 'package:intensiv_wise/user_list_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/userList': (context) => const UserListPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  int currentIndex = 0;
  List<String> _frontImageUrls = [];
  bool isLoading = true;
  List<Map<String, dynamic>> accounts = [];

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        clearImages();
      } else {
        _loadFrontImages();
        _loadAccountsFromFirestore();
      }
    });
  }

  void clearImages() {
    setState(() {
      _frontImageUrls.clear();
      isLoading = true;
    });
  }

  Future<void> _loadAccountsFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('bankAccounts')
            .where('accountId', isEqualTo: userId)
            .get();

        List<Map<String, dynamic>> fetchedAccounts = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'ownerName': doc['ownerName'],
            'balance': doc['balance'],
          };
        }).toList();

        setState(() {
          accounts = fetchedAccounts;
        });
      } catch (e) {
        print('Error loading accounts: $e');
      }
    }
  }

  Future<void> _loadFrontImages() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      clearImages();
      String email = user.email!.replaceAll('@', '_').replaceAll('.', '_');

      try {
        ListResult result = await FirebaseStorage.instance
            .ref('customercards')
            .listAll();

        List<String> frontImages = [];

        for (var item in result.items) {
          if (item.name.startsWith(email) && item.name.contains('front')) {
            String downloadUrl = await item.getDownloadURL();
            frontImages.add(downloadUrl);
          }
        }

        if (frontImages.isEmpty) {
          print('No images to display.');
        }

        setState(() {
          _frontImageUrls = frontImages;
          isLoading = false;
        });
      } catch (e) {
        print('Error loading images: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        _frontImageUrls.clear();
        isLoading = false;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> _showAddAccountDialog() async {
    final TextEditingController ownerNameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ownerNameController,
                decoration: const InputDecoration(labelText: 'Owner Name'),
              ),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Balance'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Получаем данные из текстовых полей
                String ownerName = ownerNameController.text;
                double? balance = double.tryParse(balanceController.text);

                // Проверяем корректность данных
                if (ownerName.isNotEmpty && balance != null) {
                  await _createNewAccount(ownerName, balance);
                  ownerNameController.clear();
                  balanceController.clear();
                  Navigator.of(context).pop(); // Закрыть диалог
                } else {
                  // Если данные некорректны, показываем сообщение
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid name and balance'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewAccount(String ownerName, double balance) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String accountId = user.uid;

      try {
        await FirebaseFirestore.instance.collection('bankAccounts').add({
          'accountId': accountId,
          'ownerName': ownerName,
          'balance': balance,
        });
        _loadAccountsFromFirestore(); // Обновляем список счетов
      } catch (e) {
        print('Error creating new account: $e');
      }
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bankAccounts')
          .doc(accountId)
          .delete();
      _loadAccountsFromFirestore(); // Обновляем список счетов
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  Widget buildCard(String ownerName, double balance, String accountId) {
    return Card(
      color: Colors.deepPurple, // Фиолетовый цвет карточки
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Закругление углов
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Отступы внутри карточки
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ownerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24, // Увеличенный размер шрифта
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Balance: \$${balance.toStringAsFixed(2)}', // Форматирование баланса
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20, // Увеличенный размер шрифта
              ),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _deleteAccount(accountId); // Удаляем счет
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 0, // Поднимаем карточку выше экрана
            left: 0,
            right: 0,
            height: height * 0.5, // Увеличиваем высоту карточки
            child: Container(
              alignment: Alignment.center,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _frontImageUrls.isNotEmpty
                  ? PageView.builder(
                itemCount: _frontImageUrls.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return buildCard(
                    accounts.isNotEmpty
                        ? accounts[index % accounts.length]['ownerName']
                        : 'No accounts',
                    accounts.isNotEmpty
                        ? accounts[index % accounts.length]['balance']
                        : 0.0,
                    accounts.isNotEmpty
                        ? accounts[index % accounts.length]['id']
                        : '',
                  );
                },
              )
                  : const Center(
                child: Text(
                  'No images to display.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80, // Отступ от нижней панели
            right: 20,
            child: FloatingActionButton(
              onPressed: _showAddAccountDialog,
              tooltip: 'Add Account',
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.deepPurple,
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      // Действие для кнопки "Home"
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/userList');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
