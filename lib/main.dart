import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intensiv_wise/login_page.dart';
import 'package:intensiv_wise/profile.dart';
import 'package:intensiv_wise/user_list_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/userList': (context) => const UserListPage(),
        '/splash': (context) => SplashScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> cards = [
    {'title': 'Are you tired of unexpected expenses?', 'image': 'assets/images/h_page.png'},
    {'title': 'Imagine if you can manage your expenses in two taps', 'image': 'assets/images/h_page2.png'},
    {'title': 'Or synchronize your bank card with the application', 'image': 'assets/images/h_page3.png'},
    {'title': 'So, what are you waiting for? Learn to Spend Wisely', 'image': 'assets/images/h_page4.png'},
  ];

  bool isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signOut(); // Выход из сессии при каждом запуске приложения
  }

  // Метод для смены карточки с анимацией
  void _onNextPage() {
    if (_currentPage < cards.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Переход к экрану авторизации
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF060808), Color(0xFF053641)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
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
                        // Изображение карусели
                        Expanded(
                          flex: 3,
                          child: Image.asset(
                            cards[_currentPage]['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Текст карусели
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.0),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 12.0),
                              child: Text(
                                cards[_currentPage]['title']!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          cards.length,
                              (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
                        width: _currentPage == cards.length - 1 ? 200 : 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF504FFF), Color(0xFFC69EFD)],
                          ),
                        ),
                        child: InkWell(
                          onTap: _onNextPage,
                          child: Center(
                            child: Text(
                              _currentPage == cards.length - 1 ? 'Continue' : '>',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0; // Индекс выбранной страницы
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

  // Виджеты для разных страниц
  Widget _buildHomePage() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : PageView.builder(
      controller: _pageController,
      itemCount: _frontImageUrls.length,
      itemBuilder: (context, index) {
        return Image.network(_frontImageUrls[index]);
      },
    );
  }

  Widget _buildUserListPage() {
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(accounts[index]['ownerName']),
          subtitle: Text('Balance: ${accounts[index]['balance']}'),
        );
      },
    );
  }

  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person, size: 100, color: Colors.white),
          SizedBox(height: 10),
          Text('User Profile', style: TextStyle(fontSize: 24, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF060808), Color(0xFF053641)],
                ),
              ),
            ),
          ),
          // В зависимости от выбранного индекса показываем разные страницы
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomePage(), // Главная страница
              _buildUserListPage(), // Страница со списком пользователей
              _buildProfilePage(), // Страница профиля
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CurvedNavigationBar(
              index: _currentIndex,
              height: 60.0,
              items: const <Widget>[
                Icon(Icons.home, size: 30),
                Icon(Icons.list, size: 30),
                Icon(Icons.person, size: 30),
              ],
              color: const Color(0xFF060808),
              buttonBackgroundColor: const Color(0xFF00FFFF),
              backgroundColor: Colors.transparent,
              animationDuration: const Duration(milliseconds: 400),
              onTap: (index) {
                setState(() {
                  _currentIndex = index; // Переключаем индекс на выбранную страницу
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}