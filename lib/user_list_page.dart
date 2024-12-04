import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Импортируем для форматирования даты
import 'dart:async';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({Key? key}) : super(key: key);

  @override
  _AllTransactionsPageState createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  String selectedType = 'all'; // Переменная для фильтрации (все, доходы, расходы)
  List<DocumentSnapshot> allTransactions = []; // Список для хранения всех транзакций
  List<DocumentSnapshot> filteredTransactions = [];
  // Фильтрация данных по типу
  List<DocumentSnapshot> _applyFilter(List<DocumentSnapshot> transactions) {
    if (selectedType == 'all') {
      return transactions; // Возвращаем все транзакции, если фильтр "Все"
    } else {
      return transactions.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final transactionType = data['transactionType'] ?? '';
        // Фильтруем по типу транзакции: доход или расход
        return transactionType == (selectedType == 'income' ? 'Доход' : 'Расход');
      }).toList();
    }
  }// Список для хранения отфильтрованных транзакций
  double incomeSum = 0.0; // Сумма доходов
  double expenseSum = 0.0; // Сумма расходов
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Останавливаем таймер
    super.dispose();
  }

  // Метод для получения всех транзакций из Firestore
  void _fetchTransactions() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        // Обновляем только новые транзакции
        allTransactions = snapshot.docs;
        // Применяем текущий фильтр к новым данным
        filteredTransactions = _applyFilter(allTransactions);
        _calculateSums(); // Пересчитываем суммы после загрузки данных
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить транзакции: $e')),
      );
    }
  }

  // Фильтрация данных по типу
  void _filterTransactions(String type) {
    setState(() {
      selectedType = type;

      if (type == 'all') {
        filteredTransactions = allTransactions;
      } else {
        filteredTransactions = allTransactions.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final transactionType = data['transactionType'] ?? '';
          return transactionType == (type == 'income' ? 'Доход' : 'Расход');
        }).toList();
      }
      filteredTransactions = _applyFilter(allTransactions);
      _calculateSums(); // Пересчитываем суммы после фильтрации
    });
  }

  // Метод для подсчета сумм доходов и расходов
  void _calculateSums() {
    incomeSum = 0.0;
    expenseSum = 0.0;

    for (var transaction in filteredTransactions) {
      final data = transaction.data() as Map<String, dynamic>;
      final amount = data['amount'] ?? 0.0;
      final transactionType = data['transactionType'] ?? '';

      if (transactionType == 'Доход') {
        incomeSum += amount;
      } else if (transactionType == 'Расход') {
        expenseSum += amount;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Раздел для отображения сумм доходов и расходов
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Контейнер для доходов
                Container(
                  width: 170, // Фиксированная ширина
                  height: 150, // Фиксированная высота (делаем квадрат)
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF202020), Color(0xFF070707)], // Градиент от светлого к темному
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6), // Более насыщенная тень для объема
                        blurRadius: 12, // Увеличенная размытие для большего эффекта
                        offset: const Offset(-4, -4), // Смещение тени для объема
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1), // Светлая тень для дополнительного объема
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Добавим немного отступов для содержимого
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Центрируем элементы
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Текст "Доходы:"
                        Text(
                          'Доходы',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.3), // Цвет текста
                            fontSize: 14, // Размер шрифта
                            fontWeight: FontWeight.w400, // Вес шрифта
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Текст с суммой доходов
                        Text(
                          '${incomeSum.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white, // Зеленый цвет для суммы
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Используем Expanded для динамического размещения изображения
                        Expanded(
                          child: Align(
                            alignment: Alignment.center, // Центрируем изображение
                            child: Image.asset(
                              'assets/images/in_vverh.png', // Путь к изображению
                              width: 120, // Размер изображения
                              height: 120,
                              fit: BoxFit.contain, // Чтобы изображение помещалось в контейнер
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Контейнер для расходов
                Container(
                  width: 170, // Фиксированная ширина
                  height: 150, // Фиксированная высота (делаем квадрат)
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF202020), Color(0xFF070707)], // Градиент от темного к светлому
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6), // Более насыщенная тень для объема
                        blurRadius: 12, // Увеличенная размытие для большего эффекта
                        offset: const Offset(-4, -4), // Смещение тени для объема
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1), // Светлая тень для дополнительного объема
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Центрируем элементы
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Расходы',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.3), // Цвет текста
                            fontSize: 14, // Размер шрифта
                            fontWeight: FontWeight.w400, // Вес шрифта
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Текст с суммой доходов
                        Text(
                          '${expenseSum.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white, // Зеленый цвет для суммы
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Добавляем изображение внизу
                        Expanded( // Используем Expanded для динамического заполнения пространства
                          child: Align(
                            alignment: Alignment.center, // Центрируем изображение
                            child: Image.asset(
                              'assets/images/ex_vniz.png',
                              width: 120, // Размер изображения
                              height: 120,
                              fit: BoxFit.contain, // Чтобы изображение помещалось в контейнер
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Раздел для фильтров
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedType == 'all' ? Color(0xFF00A4AA) : Color(0xFF0B0B0B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    foregroundColor: selectedType == 'all' ? Color(0xFFFFFFFF) : Color(0xFF535353),
                    elevation: 8, // Добавляем высоту для объема
                    shadowColor: selectedType == 'all' ? Colors.tealAccent : Colors.black, // Цвет тени
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Радиус для закругленных углов
                    ),
                  ),
                  onPressed: () => _filterTransactions('all'),
                  child: const Text('Все'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedType == 'expense' ? Color(0xFFC9095E) : Color(0xFF0B0B0B),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    foregroundColor: selectedType == 'expense' ? Color(0xFFFFFFFF) : Color(0xFF535353),
                    elevation: 8, // Добавляем высоту для объема
                    shadowColor: selectedType == 'expense' ? Colors.redAccent : Colors.black, // Цвет тени
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Радиус для закругленных углов
                    ),
                  ),
                  onPressed: () => _filterTransactions('expense'),
                  child: const Text('Расходы'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedType == 'income' ? Color(0xFF0863CA) : Color(0xFF0B0B0B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    foregroundColor: selectedType == 'income' ? Color(0xFFFFFFFF) : Color(0xFF535353),
                    elevation: 8, // Добавляем высоту для объема
                    shadowColor: selectedType == 'income' ? Colors.blueAccent : Colors.black, // Цвет тени
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Радиус для закругленных углов
                    ),
                  ),
                  onPressed: () => _filterTransactions('income'),
                  child: const Text('Доходы'),
                ),
              ],
            ),
          ),
          // Раздел для списка транзакций

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0), // Отступы справа и слева
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A), // Цвет фона контейнера
                  borderRadius: BorderRadius.circular(30), // Закругленные углы
                ),
                child: ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final data = filteredTransactions[index].data() as Map<String, dynamic>;

                    // Форматирование даты
                    final formattedDate = DateFormat('dd.MM.yyyy').format(data['date'].toDate());

                    // Иконки для категорий
                    final icon = data['transactionType'] == 'Доход'
                        ? Icons.attach_money // Иконка для доходов (денежные банкноты)
                        : Icons.credit_card; // Иконка для расходов (кредитная карта)

                    // Цвет иконки
                    final iconColor = data['transactionType'] == 'Доход'
                        ? Color(0xFF0092FA) // Цвет для дохода
                        : Color(0xFFC9095E); // Цвет для расхода

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10), // Отступы внутри элемента
                      leading: Container(
                        width: 44, // Ширина контейнера
                        height: 44, // Высота контейнера (делаем круглый контейнер)
                        decoration: BoxDecoration(
                          color: Colors.grey[850], // Серый фон
                          shape: BoxShape.circle, // Круглая форма
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6), // Черная тень с прозрачностью
                              blurRadius: 8, // Размытие тени
                              offset: Offset(0, 4), // Смещение тени
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor, // Цвет иконки в зависимости от типа транзакции
                          size: 24,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6), // Черная тень с прозрачностью
                              blurRadius: 8, // Размытие тени
                              offset: Offset(2, 2), // Смещение тени
                            ),
                          ],// Размер иконки
                        ),
                      ),
                      title: Text(
                        data['category'],
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                      subtitle: Text(
                        formattedDate, // Используем отформатированную дату
                        style: TextStyle(color: Colors.white.withOpacity(0.2)),
                      ),
                      trailing: Text(
                        '₽${data['amount']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: data['transactionType'] == 'Доход' ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
