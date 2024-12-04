import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'dart:async';
import 'package:pie_chart/pie_chart.dart'; // Для диаграммы

class DiagramTransactionsPage extends StatefulWidget {
  const DiagramTransactionsPage({Key? key, required Map<String, dynamic> selectedAccount}) : super(key: key);

  @override
  _DiagramTransactionsPageState createState() => _DiagramTransactionsPageState();
}

class _DiagramTransactionsPageState extends State<DiagramTransactionsPage> {
  String selectedType = 'all'; // Переменная для фильтрации (все, доходы, расходы)
  List<DocumentSnapshot> allTransactions = []; // Список для хранения всех транзакций
  List<DocumentSnapshot> filteredTransactions = []; // Список для хранения отфильтрованных транзакций
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
  }

  // Фильтрация данных по типу
  void _filterTransactions(String type) {
    setState(() {
      selectedType = type;
      filteredTransactions = _applyFilter(allTransactions); // Применяем фильтрацию
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
                  tween: Tween<double>(begin: 0.0, end: incomeSum + expenseSum),
                  duration: Duration(seconds: 2),
                  builder: (context, double value, child) {
                    final double incomeValue = incomeSum * (value / (incomeSum + expenseSum));
                    final double expenseValue = expenseSum * (value / (incomeSum + expenseSum));

                    return PieChart(
                      dataMap: {
                        'Доходы': incomeValue,
                        'Расходы': expenseValue,
                      },
                      chartType: ChartType.ring,
                      chartRadius: MediaQuery.of(context).size.width / 2.5,
                      centerText: 'Суммы',
                      legendOptions: LegendOptions(
                        showLegends: true,
                        legendPosition: LegendPosition.bottom,
                      ),
                      colorList: [Color(0xFF0092FA), Color(0xFFC9095E)],
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
                    backgroundColor: selectedType == 'income' ? Color(0xFF0092FA) : Color(0xFF0B0B0B),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
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
        ],
      ),
    );
  }
}
