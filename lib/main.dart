import 'package:flutter/material.dart';
import 'login_page.dart';
import 'profile.dart';
// import 'add_card_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

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
        // '/addCard': (context) => const AddCardPage(),
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

  @override
  void initState() {
    super.initState();
    // Подписка на изменения состояния аутентификации
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        clearImages(); // Очищаем изображения, если пользователь вышел
      } else {
        _loadFrontImages(); // Загружаем изображения, если пользователь вошел
      }
    });
  }

  // Метод для очистки списка изображений
  void clearImages() {
    setState(() {
      _frontImageUrls.clear();
      isLoading = true; // Указываем состояние загрузки
    });
  }

  Future<void> _loadFrontImages() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      clearImages(); // Очищаем предыдущие изображения при входе пользователя
      String email = user.email!.replaceAll('@', '_').replaceAll('.', '_');

      try {
        // Получаем все изображения в папке 'customercards'
        ListResult result = await FirebaseStorage.instance
            .ref('customercards')
            .listAll();

        List<String> frontImages = [];

        for (var item in result.items) {
          // Проверяем, начинается ли имя элемента с идентификатора электронной почты пользователя
          if (item.name.startsWith(email) && item.name.contains('front')) {
            String downloadUrl = await item.getDownloadURL();
            frontImages.add(downloadUrl);
          }
        }

        if (frontImages.isEmpty) {
          print('Нет изображений для отображения.');
        }

        setState(() {
          _frontImageUrls = frontImages;
          isLoading = false; // Завершаем загрузку
        });
      } catch (e) {
        print('Ошибка при загрузке изображений: $e');
        setState(() {
          isLoading = false; // Завершаем загрузку даже при ошибке
        });
      }
    } else {
      // Пользователь не вошел
      setState(() {
        _frontImageUrls.clear();
        isLoading = false; // Завершаем загрузку, если пользователь не вошел
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Градиентный фон
          Positioned(
            top: height - 98,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Поисковая строка
          Positioned(
            top: 112,
            left: (width - 340) / 2,
            child: Container(
              width: 340,
              height: 37,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(172, 172, 172, 0.29),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF008E8E)),
                    SizedBox(width: 10),
                    Text(
                      'Поиск',
                      style: TextStyle(
                        color: Color.fromRGBO(172, 172, 172, 0.65),
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Карты изображений из Firebase
          Positioned(
            top: 160,
            bottom: 98,
            left: 0,
            right: 0,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : PageView.builder(
              itemCount: _frontImageUrls.isNotEmpty ? _frontImageUrls.length : 1,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (_frontImageUrls.isNotEmpty) {
                  return Center(
                    child: buildCardFromUrl(_frontImageUrls[index]),
                  );
                } else {
                  return const Center(
                    child: Text(
                      'Нет счетов',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
              },
            ),
          ),
          // Нижняя панель навигации
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 98,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.home,
                      color: Color(0xFF008E8E),
                    ),
                    iconSize: 28,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.credit_card,
                      color: Colors.grey,
                    ),
                    iconSize: 28,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.account_circle,
                      color: Colors.grey,
                    ),
                    iconSize: 28,
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Spend',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                  color: Color(0xFF008E8E),
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'Wise',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/addCard');
              },
            ),
          ),
        ],
      ),
    );
  }

  // Визуализация карты по URL
  Widget buildCardFromUrl(String imageUrl) {
    return Container(
      width: 250,
      height: 450,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}