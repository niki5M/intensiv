import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  double profileFieldSpacing = 25.0;
  double actionButtonSpacing = 20.0;
  double topPadding = 40.0;
  double profileFieldHeight = 37.0; // Высота полей профиля

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
        creationDate = user.metadata.creationTime?.toLocal().toString().split(' ')[0] ?? 'Неизвестно';
      });

      // Загружаем данные из Firebase каждый раз при входе
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('customers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          nickname = data['cusname'] ?? '';
          profileImageUrl = data['profileimg'] ?? '';
          _nicknameController.text = nickname;
        });
      } else {
        // Если данные не существуют, очищаем
        setState(() {
          nickname = '';
          profileImageUrl = '';
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
        Navigator.pushReplacementNamed(context, '/');
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
        final ref = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');
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

        await FirebaseFirestore.instance.collection('customers').doc(user.uid).set({
          'cusname': nickname,
          'profileimg': imageUrl ?? profileImageUrl,
        }, SetOptions(merge: true));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black, // Черный фон для всего экрана
        body: SingleChildScrollView( // Добавлено для прокрутки
        child: Column(
        children: [
        Padding(
        padding: EdgeInsets.only(top: topPadding),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const SizedBox(width: 48), // Отступ слева для выравнивания
    // Кнопка выхода
    IconButton(
    icon: const Icon(Icons.logout, color: Color(0xFF00BCBC)),
    onPressed: _signOut,
    ),
    ],
    ),
    ),
    const SizedBox(height: 20), // Дополнительный отступ
    // Надпись DiscountKeeper
    RichText(
    text: const TextSpan(
    children: [
    TextSpan(
    text: 'Spend',
    style: TextStyle(
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w800,
    fontSize: 43,
    color: Color(0xFF00BCBC),
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
    fontSize: 43,
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
    const SizedBox(height: 20), // Дополнительный отступ
    SizedBox(
    height: 120,
    child: Center(
    child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    RichText(
    text: TextSpan(
    children: [
    const TextSpan(
    text: 'Профиль, ',
    style: TextStyle(
    color: Colors.white,
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.bold,
    fontSize: 22,
    ),
    ),
    TextSpan(
    text: nickname, // Никнейм пользователя
      style: const TextStyle(
        color: Color(0xFF00BCBC), // Цвет никнейма
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
    ),
    ],
    ),
    ),
      const SizedBox(height: 8),

    ],
    ),
    ),
    ),
    ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileImage(),
                SizedBox(height: profileFieldSpacing),
                _buildProfileField('Ваша почта', email),
                SizedBox(height: profileFieldSpacing),
                _buildProfileField('Дата создания аккаунта', creationDate),
                SizedBox(height: profileFieldSpacing),
                _buildNicknameField(),
              ],
            ),
          ),
          SizedBox(height: actionButtonSpacing),
          _buildSaveButton(),
        ],
        ),
        ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 75 ,
        backgroundImage: _selectedImage != null
            ? FileImage(_selectedImage!)
            : (profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null) as ImageProvider?,
        child: profileImageUrl.isEmpty && _selectedImage == null
            ? const Icon(Icons.camera_alt, size: 50, color: Colors.white70)
            : null,
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        SizedBox(
          height: profileFieldHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildNicknameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ваш никнейм',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        SizedBox(
          height: profileFieldHeight,
          child: TextField(
            controller: _nicknameController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              hintText: 'Введите ваш никнейм',
              hintStyle: TextStyle(
                color: Colors.white54,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00BCBC)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00BCBC)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Скрыть клавиатуру
        _saveProfile(); // Метод для сохранения профиля
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width * 0.85,
        height: 53,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5AF4F4), Color(0xFF008E8E)], // Градиент для кнопки
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center( // Добавлено Center для центрирования текста
          child: const Text(
            'Сохранить изменения',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}