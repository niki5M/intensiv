import 'dart:convert'; // Для конвертации строки в байты
import 'package:crypto/crypto.dart'; // Для хеширования пароля
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

bool _isPasswordVisible = false;

class LoginPageState extends State<LoginPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Контроллер для подтверждения пароля
  bool _isLoading = false;
  bool _isLoginMode = true; // Переменная для отслеживания режима (вход/регистрация)

  @override
  void initState() {
    super.initState();
    _checkSession(); // Проверяем сессию при запуске
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Освобождаем контроллер
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
    String confirmPassword = _confirmPasswordController.text
        .trim(); // Получаем подтвержденный пароль

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

    if (!_isLoginMode &&
        password != confirmPassword) { // Проверка на соответствие паролей
      _showErrorSnackBar('Пароли не совпадают.');
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
    CollectionReference customers = FirebaseFirestore.instance.collection(
        'customers');

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
    final width = MediaQuery
        .of(context)
        .size
        .width;
    final isKeyboardVisible = MediaQuery
        .of(context)
        .viewInsets
        .bottom > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF060808),
                  Color(0xFF053641),
                ],
              ),
            ),
          ),
          Positioned(
            top: -150,
            left: 0,
            right: -70,
            child: Image.asset(
              _isLoginMode
                  ? 'assets/images/lll.png' // Изображение для режима входа
                  : 'assets/images/sss.png',
              // Изображение для режима регистрации
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 1.1,
              height: 450,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    if (!isKeyboardVisible) ...[
                      Text(
                        _isLoginMode ? 'Log in' : 'Sign Up',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 15),
                    _buildTextField(_loginController, 'Email'),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _passwordController, 'Password', obscureText: true),
                    if (!_isLoginMode) ...[
                      // Показываем поле подтверждения пароля только при регистрации
                      const SizedBox(height: 16),
                      _buildTextField(
                          _confirmPasswordController, 'Confirm Password',
                          obscureText: true),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _submitLogin();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: width * 0.85,
                        height: 65,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF504FFF), Color(0xFFC69EFD)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.black)
                              : Text(
                            _isLoginMode ? 'Log In' : 'Sign Up',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    Center(
                      child: TextButton(
                        onPressed: _toggleMode,
                        child: Text(
                          _isLoginMode
                              ? 'Dont have an account? Sign Up'
                              : 'Already have an account? Log In',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w300,
                            color: Colors.grey,
                          ),
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

  // Метод для создания текстового поля с паролем

  Widget _buildTextField(TextEditingController controller,
      String label, {
        bool obscureText = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText ? !_isPasswordVisible : false,
          style: const TextStyle(
            color: Colors.grey,
          ),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: obscureText
                ? IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            )
                : null,
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                  color: Colors.transparent), // Прозрачная нижняя граница
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                  color: Colors.transparent), // Прозрачная при фокусе
            ),
          ),
        ),
        const SizedBox(height: 4), // Отступ между полем ввода и границей
        Container(
          width: MediaQuery
              .of(context)
              .size
              .width * 0.85,
          height: 2.0, // Высота границы
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF504FFF), // Начальный цвет градиента
                Color(0xFFC69EFD), // Конечный цвет градиента
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(15), // Округление краев границы
          ),
        ),
      ],
    );
  }
}