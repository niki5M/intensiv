import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intensiv_wise/Subscription_page.dart'; // Импортируем страницу подписки
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final Logger _logger = Logger('ProfilePage');
  final TextEditingController _nicknameController = TextEditingController();
  String email = '';
  String creationDate = '';
  String nickname = '';
  String profileImageUrl = '';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? subscriptionEndDate; // Новое поле для даты окончания подписки

  double profileFieldSpacing = 25.0;
  double actionButtonSpacing = 20.0;
  double topPadding = 40.0;
  double profileFieldHeight = 37.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? '';
        creationDate =
            user.metadata.creationTime?.toLocal().toString().split(' ')[0] ??
                'Неизвестно';
      });

      // Загружаем данные из Firebase
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(
          'customers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          nickname = data['cusname'] ?? '';
          profileImageUrl = data['profileimg'] ?? '';
          subscriptionEndDate = data['subscription_end_date'] ??
              null; // Получаем дату окончания подписки
          _nicknameController.text = nickname;
        });
      } else {
        setState(() {
          nickname = '';
          profileImageUrl = '';
          subscriptionEndDate = null;
          _nicknameController.clear();
        });
      }
    }
  }

  Future<void> _signOut() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение выхода'),
          content: const Text('Вы действительно хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Остаемся на странице
              },
              child: const Text('Остаться'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Подтверждаем выход
              },
              child: const Text('Да'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        // Переход на SplashScreen после выхода
        Navigator.pushReplacementNamed(context, '/splash');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выхода: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance.ref()
            .child('profile_images')
            .child('${user.uid}.jpg');
        await ref.putFile(image);
        return await ref.getDownloadURL();
      }
    } catch (e) {
      _logger.severe('Ошибка при загрузке изображения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке изображения: $e')),
      );
    }
    return null;
  }

  Future<void> _saveProfile() async {
    String nickname = _nicknameController.text;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _uploadImage(_selectedImage!);
        }

        // Обновление данных в Firebase
        await FirebaseFirestore.instance.collection('customers')
            .doc(user.uid)
            .set({
          'cusname': nickname,
          'profileimg': imageUrl ?? profileImageUrl,
          // если изображение не выбрано, оставляем старое
        }, SetOptions(merge: true));

        // Обновляем UI, чтобы отобразить изменения
        setState(() {
          this.nickname = nickname;
          if (imageUrl != null) {
            profileImageUrl = imageUrl;
          }
        });

        _logger.info('Профиль успешно сохранен');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль сохранен')),
        );
      } catch (e) {
        _logger.severe('Ошибка при сохранении профиля: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  // Переход на страницу подписки
  Future<void> _goToSubscriptionPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubscriptionPage()),
    );
  }

// Открытие диалога изменения профиля
  void _openEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Скругленные углы
          ),
          backgroundColor: Colors.black, // Черный фон
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null) as ImageProvider<Object>?,
                    // Исправлено: правильный тип ImageProvider
                    child: profileImageUrl.isEmpty && _selectedImage == null
                        ? const Icon(
                        Icons.camera_alt, size: 50, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white),
                  // Белый текст в поле ввода
                  decoration: InputDecoration(
                    labelText: 'Имя пользователя',
                    labelStyle: const TextStyle(color: Colors.white70),
                    // Светлый цвет для лейбла
                    enabledBorder: UnderlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.white70), // Подчеркнутая линия
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.white), // Подчеркнутая линия при фокусе
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Секции для кнопок "Отмена" и "Сохранить"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop(); // Закрываем диалог без изменений
                      },
                      child: const Text(
                        'Отмена',
                        style: TextStyle(
                            color: Colors.white), // Белый текст для кнопки
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _saveProfile(); // Сохраняем изменения
                        Navigator.of(context).pop(); // Закрываем диалог
                      },
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(
                            color: Colors.white), // Белый текст для кнопки
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фон с градиентом
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ Color(0xFF000000),Color(0xFF3C0014)],stops: [0.5, 1.0],
              ),
            ),
          ),

          // Фон с изображением
          Positioned(
            top: -220,
            left: 80,
            right: 0,
            child: Image.asset(
              'assets/images/prof.png',
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              height: 700,
              fit: BoxFit.cover,
            ),
          ),

          // Контейнер с содержимым
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 150),
                // Отступ для аватара
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null) as ImageProvider?,
                      child: profileImageUrl.isEmpty && _selectedImage == null
                          ? const Icon(
                          Icons.camera_alt, size: 50, color: Colors.white70)
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 45.0),

                // Имя пользователя и кнопка редактирования
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nickname.isNotEmpty ? nickname : 'Без имени',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _openEditProfileDialog,
                    ),
                  ],
                ),

                // Электронная почта и дата регистрации
                SizedBox(height:15.0),
                Text(
                  'Email: $email',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300),
                ),
                SizedBox(height: 20.0),

                SizedBox(height: profileFieldSpacing),

                // Лозунг перед кнопкой премиума
                subscriptionEndDate != null
                    ? Text(
                  'Ваша подписка действует до: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(subscriptionEndDate!))}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Color(0x99FFFFFF),
                  ),
                )
                    : Text(
                  'Получите дополнительные возможности с премиум-аккаунтом!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Color(0x99FFFFFF),
                  ),
                ),

                SizedBox(height: actionButtonSpacing),

                // Кнопка Premium, растянутая по ширине
                Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Colors.transparent),
                      elevation: MaterialStateProperty.all(0),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      )),
                      padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(vertical: 20)),
                      minimumSize: MaterialStateProperty.all(
                          Size(double.infinity, 50)),
                    ),
                    onPressed: _goToSubscriptionPage,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF82A6E8), Color(0xC000BABA), Color(0xFF002FA3)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 60), // Отступ перед кнопкой выхода
              ],
            ),
          ),

          // Кнопка выхода расположена внизу, прямо над панелью навигации
          Positioned(
            bottom: 45,
            right: -15, // Устанавливаем отступ от правого края
            child: ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
                elevation: MaterialStateProperty.all(0),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                )),
                padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(vertical: 18, horizontal: 40)),
              ),
              onPressed: _signOut,
              icon: Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 24,
              ),
              label: Text(
                'Выйти',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}