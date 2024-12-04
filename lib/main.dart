import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intensiv_wise/login_page.dart';
import 'package:intensiv_wise/pin_code_screen.dart';
import 'package:intensiv_wise/profile.dart';
import 'package:intensiv_wise/user_list_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intensiv_wise/userHome_page.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

import 'GoalsAndProjectionsPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InitialScreen(), // Указываем экран проверки авторизации
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/userList': (context) => const AllTransactionsPage(),
        '/pin': (context) => const PinCodeScreen(),
      },
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  Future<Widget> _determineStartScreen() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Если пользователь авторизован, показываем экран ввода пин-кода
      return const PinCodeScreen();
    } else {
      // Если пользователь не авторизован, показываем SplashScreen
      return const SplashScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Показываем загрузку, пока определяется стартовый экран
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return snapshot.data!;
        } else {
          return const Scaffold(
            body: Center(child: Text('Ошибка загрузки')),
          );
        }
      },
    );
  }
}
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _circle1Animation;
  late Animation<Offset> _circle2Animation;

  final Random _random = Random();
  int _currentPage = 0;

  late double screenWidth;
  late double screenHeight;

  final List<Map<String, String>> cards = [
    {'title': 'Are you tired of unexpected expenses?'},
    {'title': 'Imagine if you can manage your expenses in two taps'},
    {'title': 'Or synchronize your bank card with the application'},
    {'title': 'So, what are you waiting for?'},
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    _circle1Animation = _createRandomOffsetAnimation();
    _circle2Animation = _createRandomOffsetAnimation();
  }

  Animation<Offset> _createRandomOffsetAnimation() {
    return Tween<Offset>(
      begin: _randomOffset(),
      end: _randomOffset(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  Offset _randomOffset() {
    return Offset(
      _random.nextDouble() * screenWidth,
      _random.nextDouble() * screenHeight,
    );
  }

  void _onNextPage() {
    if (_currentPage < cards.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Определяем, куда переходить: Login или PinCode
      FirebaseAuth.instance.currentUser == null
          ? Navigator.pushReplacementNamed(context, '/login')
          : Navigator.pushReplacementNamed(context, '/pin');
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBlurredCircle(Color color) {
    return Container(
      width: 0,
      height: 0,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 250,
            spreadRadius: 200,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Фон с анимацией
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      left: _circle1Animation.value.dx,
                      top: _circle1Animation.value.dy,
                      child: _buildBlurredCircle(Colors.blue.withOpacity(0.3)),
                    ),
                    Positioned(
                      left: _circle2Animation.value.dx,
                      top: _circle2Animation.value.dy,
                      child: _buildBlurredCircle(Colors.pink.withOpacity(0.3)),
                    ),
                  ],
                );
              },
            ),
          ),
          // Изображение, выходящее за пределы экрана справа и вверх
          Positioned(
            top: -220.0,  // Смещаем изображение вверх на 90
            right: -220.0,  // Смещаем изображение правее
            child: Image.asset(
              'assets/images/h_page.png', // Путь к вашему изображению
              width: 750, // Увеличиваем ширину изображения
              height: 700, // Увеличиваем высоту изображения
              fit: BoxFit.cover, // Растягиваем изображение, чтобы оно заполнило отведённую область
            ),
          ),
          // Основной контент
          Column(
            children: [
              const SizedBox(height: 380), // Отступ, чтобы текст был ниже середины экрана
              Expanded(
                flex: 1,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Column(
                      key: ValueKey<int>(_currentPage),
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
                              child: Align(
                                alignment: Alignment.centerLeft, // Прикрепляем текст к левому краю
                                child: Text.rich(
                                  TextSpan(
                                    text: cards[_currentPage]['title']!,
                                    style: const TextStyle(
                                      fontSize: 29,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    children: _currentPage == 3
                                        ? [
                                      TextSpan(
                                        text: ' Learn to ',
                                        style: const TextStyle(
                                          fontSize: 29,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Spend Wisely',
                                        style: TextStyle(
                                          fontSize: 29,
                                          fontWeight: FontWeight.w700,
                                          foreground: Paint()
                                            ..shader = LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [Colors.pink, Colors.cyan],
                                              stops: [0.6, 1.0],  // Розовый занимает 70% и голубой — 30%
                                            ).createShader(Rect.fromLTWH(0.0, 0.0, 250.0, 70.0)), // Увеличиваем ширину, чтобы охватить большую часть текста
                                        ),
                                      ),
                                    ]
                                        : [],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Индикаторы и кнопка с отступами
              Padding(
                padding: const EdgeInsets.only(bottom: 60.0, left: 30.0, right: 30.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          cards.length,
                              (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentPage == index ? 24 : 12,
                              height: 12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6.0),
                                color: _currentPage == index
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFFFFFFFF).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == cards.length - 1 ? 155 : 155,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        child: InkWell(
                          onTap: _onNextPage,
                          child: const Center(
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PinCodeScreen extends StatefulWidget {
  const PinCodeScreen({super.key});

  @override
  _PinCodeScreenState createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  final TextEditingController _pinController = TextEditingController();

  // Функция для проверки пин-кода в Firestore
  Future<void> _verifyPin() async {
    String enteredPin = _pinController.text;
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, войдите в систему.')),
      );
      return;
    }

    try {
      // Ищем документ, где поле `userId` совпадает с UID текущего пользователя
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: user.uid) // Условие поиска
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        // Предполагаем, что документ один (только один пользователь с таким UID)
        DocumentSnapshot userDoc = userSnapshot.docs.first;

        // Получаем пин-код из документа
        String storedPin = userDoc['pin'] ?? '';

        if (enteredPin == storedPin) {
          // Пин-код верный, переходим на главный экран
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Сообщаем об ошибке
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Неверный пин-код!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь не найден.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  // Функция для добавления цифры в поле пин-кода
  void _addDigit(String digit) {
    if (_pinController.text.length < 4) {
      _pinController.text += digit;
      _pinController.selection = TextSelection.collapsed(offset: _pinController.text.length);
    }
  }

  // Функция для удаления последнего символа
  void _deleteDigit() {
    if (_pinController.text.isNotEmpty) {
      _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
      _pinController.selection = TextSelection.collapsed(offset: _pinController.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Черный фон
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Введите Пин-код', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Поле для ввода пин-кода
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Пин-код',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 24),
              maxLength: 4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Панель с кнопками
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12, // 9 цифр + кнопка удаления и кнопка для подтверждения
              itemBuilder: (context, index) {
                String label;
                if (index < 9) {
                  label = (index + 1).toString();
                } else if (index == 9) {
                  label = '0';
                } else if (index == 10) {
                  label = '←'; // Кнопка удаления
                } else {
                  label = 'Войти'; // Кнопка для проверки пин-кода
                }

                return GestureDetector(
                  onTap: () {
                    if (index < 9) {
                      _addDigit(label); // Добавляем цифру
                    } else if (index == 9) {
                      _addDigit(label); // Добавляем 0
                    } else if (index == 10) {
                      _deleteDigit(); // Удаляем последнюю цифру
                    } else {
                      _verifyPin(); // Проверяем пин-код
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(80),
                      border: Border.all(
                        width: 2.0,
                        color: Colors.transparent, // Цвет фона обводки
                      ),
                      gradient: const LinearGradient(
                        colors: [Colors.black, Colors.grey],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
  int _currentIndex = 0;
  List<String> _frontImageUrls = [];
  bool isLoading = true;
  List<Map<String, dynamic>> accounts = [];
  final PageController _pageController = PageController();

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


  final TextEditingController _accountTypeController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  Future<void> _createBankAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String accountType = _accountTypeController.text.trim();
      double balance = double.parse(_balanceController.text.trim());

      try {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('bankAccounts')
            .add({
          'userId': user.uid,
          'accountType': accountType,
          'balance': balance,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Очистите поля формы
        _accountTypeController.clear();
        _balanceController.clear();

        // Обновите список счетов
        await _loadAccountsFromFirestore();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Банковский счёт создан с ID: ${docRef.id}'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании банковского счёта: $e'),
          ),
        );
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
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildUserHomePage() {
    return const UserAccountsPage();
  }

  Widget _buildUserListPage() {
    return const AllTransactionsPage();
  }

  Widget _buildProfilePage() {
    return const ProfilePage();
  }

  Widget _buildGoalsPage() {
    return RemindersPage(); // Ваша существующая страница целей
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        extendBody: true, // Эта строка добавлена
        bottomNavigationBar: CurvedNavigationBar(
          index: _currentIndex,
          height: 50.0,
          items: const <Widget>[
            Icon(Icons.supervised_user_circle_rounded, size: 30, color: Colors.white),
            Icon(Icons.home, size: 30, color: Colors.white),
            Icon(Icons.perm_identity, size: 30, color: Colors.white),
            Icon(Icons.flag, size: 30, color: Colors.white), // Новая кнопка для целей
          ],
          color: Colors.black,
          buttonBackgroundColor: Colors.black,
          backgroundColor: Color(0xFF1A1A1A),
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildUserListPage(),
            _buildUserHomePage(),
            _buildProfilePage(),
            _buildGoalsPage(), // Новая страница для целей
          ],
        ),
      ),
    );
  }

}