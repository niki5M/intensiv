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
                            color: Colors.white),
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
                colors: [Color(0xFF000000), Color(0xFF002C3C)],
                stops: [0.25, 1.0],
              ),
            ),
          ),

          // Контейнер с содержимым
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 90),
                // Отступ для аватара
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 70, // Размер круга
                      backgroundColor: Colors.transparent, // Прозрачный фон
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null) as ImageProvider?,
                      child: profileImageUrl.isEmpty && _selectedImage == null
                          ? ClipOval(
                        child: Container(
                          width: 140, // Ширина контейнера
                          height: 140, // Высота контейнера
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF503FFF), Color(0xFFC69EFD)],
                            ),
                            border: Border.all( // Добавляем белую рамку
                              color: Colors.white, // Цвет рамки
                              width: 1, // Ширина рамки
                            ),
                            shape: BoxShape.circle, // Устанавливаем форму круга
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/avatar.png', // Путь к изображению
                              width: 100, // Размер изображения (не зависит от круга)
                              height: 100, // Размер изображения
                              fit: BoxFit.contain, // Сохраняет пропорции изображения
                            ),
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 10), // Отступ после аватара

                // Имя пользователя и email
                Center(  // Центрируем оба текста
                  child: Column(
                    children: [
                      Text(
                        nickname.isNotEmpty ? nickname : 'Без имени',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10), // Отступ между текстами
                      Text(
                        '$email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: 20), // Отступ перед кнопкой редактирования профиля

                      // Кнопка редактирования профиля
                      TextButton(
                        onPressed: _openEditProfileDialog, // Ваше действие
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFF1E1E1E), // Серый фон
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Отступы
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Color(0xFF2A2A2A), // Цвет бордера
                              width: 1.0, // Толщина бордера
                            ),
                            borderRadius: BorderRadius.circular(12), // Скругленные углы
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Минимальный размер строки
                          children: [
                            // Отступ между иконкой и текстом
                            Text(
                              'Редактировать профиль',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.edit, // Иконка карандаша
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),  // Отступ перед серым блоком

                      // Пустой серый блок с информацией о подписке
                      // Пустой серый блок с информацией о подписке
                      Container(
                        width: 320, // Растягиваем блок на всю ширину
                        height: 130, // Высота блока
                        decoration: BoxDecoration(
                          color: Color(0xFF1E1E1E), // Серый цвет
                          borderRadius: BorderRadius.circular(12), // Скругленные углы
                          border: Border.all(
                            color: Color(0xFF2A2A2A), // Цвет бордера
                            width: 1.0, // Толщина бордера
                          ),
                        ),
                        padding: EdgeInsets.all(16),
                        child: subscriptionEndDate != null
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Заголовок "Активная подписка" по центру сверху
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                'Активная подписка',
                                style: TextStyle(
                                  fontSize: 14, // Размер шрифта для заголовка
                                  fontWeight: FontWeight.bold, // Сделать жирным
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 8), // Отступ между заголовком и остальной информацией

                            // Маленький фиолетовый блок с текстом "Premium"
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12), // Отступы внутри блока
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF503FFF), Color(0xFFC69EFD)],
                                ),
                              ),
                              child: Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 8), // Отступ между блоком "Premium" и датой
                            Text(
                              'Активна до: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(subscriptionEndDate!))}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          'Получите дополнительные возможности с премиум-аккаунтом!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                // Уведомления и настройки безопасности
                Center(
                  child: Container(
                    width: 320, // Растягиваем блок на всю ширину
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E1E), // Серый фон
                      borderRadius: BorderRadius.circular(12), // Скругленные углы
                      border: Border.all(
                        color: Color(0xFF2A2A2A), // Цвет бордера
                        width: 1.0, // Толщина бордера
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Уведомления с переключателем и иконкой
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8), // Отступ между иконкой и текстом
                                Text(
                                  'Уведомления',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: true, // Замените true на переменную, если требуется логика
                              onChanged: (value) {
                                setState(() {
                                  // Логика изменения состояния
                                });
                              },
                              activeColor: Color(0xFF4A90E2),
                            ),
                          ],
                        ),
                        SizedBox(height: 10), // Отступ между строками

                        // Пин-код с переключателем и иконкой
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8), // Отступ между иконкой и текстом
                                Text(
                                  'Пин-код',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: false, // Замените false на переменную, если требуется логика
                              onChanged: (value) {
                                setState(() {
                                  // Логика изменения состояния
                                });
                              },
                              activeColor: Color(0xFF4A90E2),
                            ),
                          ],
                        ),
                        SizedBox(height: 10), // Отступ между строками

                        // Кнопка выхода из аккаунта
                        Center(
                          child: ElevatedButton.icon(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Color(0xFF2A2A2A)),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              )),
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                            ),
                            onPressed: _signOut,
                            icon: Icon(
                              Icons.exit_to_app,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Выйти из аккаунта',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 60), // Отступ перед кнопкой выхода
              ],
            ),
          ),
        ],
      ),
    );
  }
}