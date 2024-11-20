import 'dart:convert'; // Для конвертации строки в байты
import 'package:crypto/crypto.dart'; // Для хеширования пароля
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/animation.dart';
import 'dart:math';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isAgreedToTerms = false; // Для галочки соглашения

  late AnimationController _controller;
  late Animation<Offset> _circle1Animation;
  late Animation<Offset> _circle2Animation;

  @override
  void initState() {
    super.initState();
    _checkSession();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true); // Плавный возврат по окончанию анимации

    Random _random = Random();

    // Для первого круга траектория будет синусоидальной по оси Y и косинусоидальной по оси X
    _circle1Animation = Tween<Offset>(
      begin: Offset(1.0, -0.2),
      end: Offset(
        0.5 + 0.5 * cos(2 * pi * _random.nextDouble()),  // Плавное движение по оси X
        1.2 + 0.1 * sin(2 * pi * _random.nextDouble()),  // Плавное движение по оси Y с небольшим случайным отклонением
      ),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Для второго круга траектория будет основана на синусе по обеим осям с увеличением амплитуды
    _circle2Animation = Tween<Offset>(
      begin: Offset(0.2, -0.2),
      end: Offset(
        0.5 + 0.5 * sin(2 * pi * _random.nextDouble()),  // Плавное движение по оси X с другим смещением
        1.2 + 0.2 * cos(2 * pi * _random.nextDouble()),  // Плавное движение по оси Y, но с более широким отклонением
      ),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Проверяем наличие сохраненной сессии и автоматически входим в аккаунт
  Future<void> _checkSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail != null) {
      // Если сохранен email, пытаемся автоматически войти в систему
      setState(() {
        _isLoading = true;
      });

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Пользователь уже аутентифицирован
          Navigator.pushNamed(context, '/home');
        }
      } catch (e) {
        _showErrorSnackBar('Ошибка автоматического входа: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Метод для выхода из аккаунта и удаления сохраненной сессии
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail'); // Удаляем сохраненный email
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Метод для хеширования пароля
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Метод для проверки формата email
  bool _isEmailValid(String email) {
    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  // Метод для отправки данных для входа или регистрации
  Future<void> _submitLogin() async {
    String email = _loginController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim(); // Получаем подтвержденный пароль

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Пожалуйста, введите email и пароль.');
      return;
    }

    if (!_isEmailValid(email)) {
      _showErrorSnackBar('Некорректный email.');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Пароль должен содержать не менее 6 символов.');
      return;
    }

    if (!_isLoginMode && password != confirmPassword) { // Проверка на соответствие паролей
      _showErrorSnackBar('Пароли не совпадают.');
      return;
    }

    if (!_isLoginMode && !_isAgreedToTerms) { // Проверка на согласие с условиями
      _showErrorSnackBar('Пожалуйста, примите пользовательское соглашение.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Сохраняем сессию пользователя
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);

        print('User logged in: ${FirebaseAuth.instance.currentUser?.email}');
        Navigator.pushNamed(context, '/home');
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String uid = userCredential.user?.uid ?? '';
        await _addUserToFirestore(email, _hashPassword(password), uid);

        // Сохраняем сессию пользователя
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);

        Navigator.pushNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showErrorSnackBar('Пользователь не найден.');
      } else if (e.code == 'wrong-password') {
        _showErrorSnackBar('Неверный пароль.');
      } else if (e.code == 'email-already-in-use') {
        _showErrorSnackBar('Этот email уже используется.');
      } else {
        _showErrorSnackBar('Ошибка: ${e.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Неизвестная ошибка: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Метод для добавления пользователя в Firestore
  Future<void> _addUserToFirestore(String email, String hashedPassword,
      String uid) async {
    CollectionReference customers = FirebaseFirestore.instance.collection('customers');

    try {
      await customers.doc(uid).set({
        'email': email,
        'hashedPassword': hashedPassword,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка при сохранении данных: ${e.toString()}');
    }
  }

  // Показываем сообщение об ошибке
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Переключение между режимами входа и регистрации
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      // Сбрасываем контроллер подтверждения пароля при переключении режимов
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Анимированные сферы с различными траекториями
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      left: _circle1Animation.value.dx * width,
                      top: _circle1Animation.value.dy * 400,
                      child: _buildBlurredCircle(Colors.blue.withOpacity(0.2)),
                    ),
                    Positioned(
                      left: _circle2Animation.value.dx * width,
                      top: _circle2Animation.value.dy * 400,
                      child: _buildBlurredCircle(Colors.pink.withOpacity(0.2)),
                    ),
                  ],
                );
              },
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoginMode ? 'Вход' : 'Регистрация',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _loginController,
                      labelText: 'Email',
                      obscureText: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      labelText: 'Пароль',
                      obscureText: !_isPasswordVisible,
                    ),
                    if (!_isLoginMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Подтвердите пароль',
                          obscureText: !_isPasswordVisible,
                        ),
                      ),
                    if (!_isLoginMode) _buildAgreementCheckbox(), // Добавляем чекбокс для соглашения
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSubmitButton(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _toggleMode,
                      child: Text(
                        _isLoginMode
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Создаем размытое кольцо
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

  // Вспомогательный метод для создания поля ввода
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      style: TextStyle(color: Colors.white),
    );
  }

  // Вспомогательный метод для создания кнопки отправки
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitLogin,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.grey.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink, Colors.cyan],
              stops: [0.4, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            _isLoginMode ? 'Log In' : 'Sign In',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Вспомогательный метод для создания чекбокса для соглашения
  Widget _buildAgreementCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Checkbox(
            value: _isAgreedToTerms,
            onChanged: (value) {
              setState(() {
                _isAgreedToTerms = value ?? false;
              });
            },
            activeColor: Colors.white,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Логика для открытия соглашения
              },
              child: Text(
                'Я согласен с пользовательским соглашением',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
