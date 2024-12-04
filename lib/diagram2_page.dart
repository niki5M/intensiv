import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'dart:async';
import 'package:pie_chart/pie_chart.dart'; // Для диаграммы

class Diagram2TransactionsPage extends StatefulWidget {
  final Map<String, dynamic> selectedAccount;
  const Diagram2TransactionsPage({Key? key, required this.selectedAccount}) : super(key: key);

  @override
  _Diagram2TransactionsPageState createState() => _Diagram2TransactionsPageState();
}

class _Diagram2TransactionsPageState extends State<Diagram2TransactionsPage> {
  String selectedCategory = 'all'; // Переменная для фильтрации по категориям
  List<DocumentSnapshot> allTransactions = []; // Список для хранения всех транзакций
  List<DocumentSnapshot> filteredTransactions = []; // Список для хранения отфильтрованных транзакций
  Map<String, double> categorySums = {}; // Сумма для каждой категории
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
          .where('account_id', isEqualTo: widget.selectedAccount['id']) // Добавлен фильтр по selectedAccount
          .get();

      setState(() {
        // Обновляем только новые транзакции
        allTransactions = snapshot.docs;
        // Применяем текущий фильтр к новым данным
        filteredTransactions = _applyCategoryFilter(allTransactions);
        _calculateCategorySums(); // Пересчитываем суммы после загрузки данных
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить транзакции: $e')));
    }
  }

  // Фильтрация данных по категории
  List<DocumentSnapshot> _applyCategoryFilter(List<DocumentSnapshot> transactions) {
    if (selectedCategory == 'all') {
      return transactions; // Возвращаем все транзакции, если фильтр "Все"
    } else {
      return transactions.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] ?? '';
        // Фильтруем по категории транзакции
        return category == selectedCategory;
      }).toList();
    }
  }

  // Фильтрация данных по категории
  void _filterTransactionsByCategory(String category) {
    setState(() {
      selectedCategory = category;
      filteredTransactions = _applyCategoryFilter(allTransactions); // Применяем фильтрацию
      _calculateCategorySums(); // Пересчитываем суммы после фильтрации
    });
  }

  // Метод для подсчета сумм по категориям
  void _calculateCategorySums() {
    categorySums.clear();

    for (var transaction in filteredTransactions) {
      final data = transaction.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'unknown';
      final amount = data['amount'] ?? 0.0;

      categorySums[category] = (categorySums[category] ?? 0.0) + amount; // Суммируем все транзакции по выбранной категории
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics by Category',
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
          // Раздел для отображения диаграммы с анимацией
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF202020), Color(0xFF070707)], // Градиент от светлого к темному
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6), // Добавляем яркое свечение
                    blurRadius: 15, // Увеличиваем размытие для более яркого свечения
                    offset: const Offset(-4, -4), // Смещение тени для объема
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3), // Светлая тень
                    blurRadius: 15,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: categorySums[selectedCategory] ?? 0.0),
                  duration: Duration(seconds: 2),
                  builder: (context, double value, child) {
                    return PieChart(
                      dataMap: {
                        selectedCategory: value,
                      },
                      chartType: ChartType.ring,
                      chartRadius: MediaQuery.of(context).size.width / 2.5,
                      centerText: 'Сумма по категориям',
                      legendOptions: LegendOptions(
                        showLegends: true,
                        legendPosition: LegendPosition.bottom,
                      ),
                      colorList: [Color(0xFF0092FA)],
                      ringStrokeWidth: 32,
                      animationDuration: Duration(seconds: 3),
                      chartValuesOptions: ChartValuesOptions(
                        showChartValues: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Раздел для фильтров по категориям
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCategory == 'all' ? Color(0xFF00A4AA) : Color(0xFF0B0B0B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    foregroundColor: selectedCategory == 'all' ? Color(0xFFFFFFFF) : Color(0xFF535353),
                    elevation: 8, // Добавляем высоту для объема
                    shadowColor: selectedCategory == 'all' ? Colors.tealAccent : Colors.black, // Цвет тени
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Радиус для закругленных углов
                    ),
                  ),
                  onPressed: () => _filterTransactionsByCategory('all'),
                  child: const Text('Все категории'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCategory == 'category1' ? Color(0xFFC9095E) : Color(0xFF0B0B0B),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    foregroundColor: selectedCategory == 'category1' ? Color(0xFFFFFFFF) : Color(0xFF535353),
                    elevation: 8, // Добавляем высоту для объема
                    shadowColor: selectedCategory == 'category1' ? Colors.redAccent : Colors.black, // Цвет тени
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Радиус для закругленных углов
                    ),
                  ),
                  onPressed: () => _filterTransactionsByCategory('category1'),
                  child: const Text('Категория 1'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCategory == 'category2' ? Color(0xFF0092FA) : Color(0xFF0B0B0B),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    foregroundColor: selectedCategory == 'category2' ? Color(0xFFFFFFFF) : Color(0xFF535353),
                    elevation: 8, // Добавляем высоту для объема
                    shadowColor: selectedCategory == 'category2' ? Colors.blueAccent : Colors.black, // Цвет тени
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Радиус для закругленных углов
                    ),
                  ),
                  onPressed: () => _filterTransactionsByCategory('category2'),
                  child: const Text('Категория 2'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
