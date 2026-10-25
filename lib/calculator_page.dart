import 'package:flutter/material.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = '0';
  String expression = '';
  bool justCalculated = false;

  void press(String value) {
    setState(() {
      if (value == 'C') {
        display = '0';
        expression = '';
        justCalculated = false;
        return;
      }

      if (value == '⌫') {
        if (justCalculated) {
          display = '0';
          justCalculated = false;
          return;
        }

        display = display.length > 1
            ? display.substring(0, display.length - 1)
            : '0';
        return;
      }

      if (value == '=') {
        _calculate();
        return;
      }

      if (['+', '−', '×', '÷'].contains(value)) {
        // إذا كانت هناك نتيجة سابقة، نستخدمها كبداية للعملية الجديدة.
        expression = '$display $value ';
        display = '0';
        justCalculated = false;
        return;
      }

      // عند كتابة رقم بعد ظهور النتيجة، نبدأ رقماً جديداً.
      if (justCalculated) {
        display = '0';
        expression = '';
        justCalculated = false;
      }

      if (value == '.' && display.contains('.')) {
        return;
      }

      if (display == '0' && value != '.') {
        display = value;
      } else {
        display += value;
      }
    });
  }

  void _calculate() {
    if (expression.isEmpty) return;

    final match = RegExp(
      r'^(-?[0-9.]+)\s*([+−×÷])\s*(-?[0-9.]+)$',
    ).firstMatch('$expression$display');

    if (match == null) return;

    final a = double.tryParse(match.group(1)!);
    final b = double.tryParse(match.group(3)!);

    if (a == null || b == null) return;

    double result;

    switch (match.group(2)) {
      case '+':
        result = a + b;
        break;
      case '−':
        result = a - b;
        break;
      case '×':
        result = a * b;
        break;
      case '÷':
        if (b == 0) {
          display = 'خطأ';
          expression = '';
          justCalculated = true;
          return;
        }
        result = a / b;
        break;
      default:
        return;
    }

    display = result % 1 == 0
        ? result.toInt().toString()
        : result.toString();

    expression = '';
    justCalculated = true;
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF26364A);
    const gold = Color(0xFFB08D57);

    final keys = [
      'C',
      '⌫',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '−',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '0',
      '.',
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3EA),
        appBar: AppBar(
          title: const Text(
            'الحاسبة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (expression.isNotEmpty)
                      Text(
                        '$expression$display',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    Text(
                      display,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: keys.length,
                  itemBuilder: (_, i) {
                    final key = keys[i];
                    final op = ['+', '−', '×', '÷', '='].contains(key);

                    return FilledButton(
                      onPressed: () => press(key),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                        op ? gold : Colors.white,
                        foregroundColor:
                        op ? Colors.white : navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
