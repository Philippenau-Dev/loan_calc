import 'package:flutter/material.dart';
import 'package:loan_calc/loan_calc.dart';

void main() => runApp(
      LoanApp(),
    );

class LoanApp extends StatelessWidget {
  const LoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoanCalculatorScreen(
        controller: LoanController(),
      ),
    );
  }
}

class LoanCalculatorScreen extends StatelessWidget {
  const LoanCalculatorScreen({
    super.key,
    required this.controller,
  });

  final LoanController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Calculator')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: LoanCalculatorForm(
          controller: controller,
        ),
      ),
    );
  }
}

class LoanCalculatorForm extends StatelessWidget {
  const LoanCalculatorForm({
    super.key,
    required this.controller,
  });

  final LoanController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoanInputFields(controller: controller),
        const SizedBox(height: 20),
        CalculationResults(
          tac: controller.loanData.tac.toString(),
          iof: controller.loanData.iof.toString(),
          monthlyPayment: controller.loanData.monthlyPayment.toString(),
        ),
        const SizedBox(height: 20),
        CalculateButton(controller: controller),
      ],
    );
  }
}

class LoanInputFields extends StatelessWidget {
  final LoanController controller;

  const LoanInputFields({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controller.amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Loan Amount',
            prefixText: '\$',
          ),
        ),
        TextFormField(
          controller: controller.termController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Term (months)',
          ),
        ),
      ],
    );
  }
}

class CalculateButton extends StatelessWidget {
  final LoanController controller;

  const CalculateButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => controller.calculateLoan(),
      child: const Text('Calculate Loan Details'),
    );
  }
}

class CalculationResults extends StatelessWidget {
  const CalculationResults({
    super.key,
    required this.tac,
    required this.iof,
    required this.monthlyPayment,
  });

  final String tac;
  final String iof;
  final String monthlyPayment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TAC: $tac'),
        Text('IOF: $iof'),
        Text('Monthly Payment: $monthlyPayment'),
      ],
    );
  }
}

class LoanData {
  double tac = 0;
  double iof = 0;
  double monthlyPayment = 0;
  String installmentOptions = '';
}

class LoanController extends ChangeNotifier {
  final LoanCalc _loanCalc = LoanCalc();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController termController = TextEditingController();
  final LoanData loanData = LoanData();
  String installmentOptions = '';

  void calculateLoan() {
    final desiredValue = double.tryParse(amountController.text) ?? 0;
    final periods = int.tryParse(termController.text) ?? 12;

    loanData.tac = _loanCalc.calculateTAC(desiredValue, 12, 250);
    loanData.iof = _loanCalc.calculateFixedIOF(
      loanAmount: desiredValue,
      annualIOFRate: 0.38,
    );

    final result = _loanCalc.generateInstallmentList(
      desiredValue: desiredValue,
      differenceInDays: 30,
      annualIOFTax: 0.38,
      dailyIOFRate: 0.0082,
      minPeriods: periods,
      maxPeriods: periods,
      monthlyInterestRate: 15.9,
      minimumInstallmentValue: 100,
      tacLimit: 250,
      tacRate: 12,
    );

    loanData.monthlyPayment = result.selectedInstallment?.installmentValue ?? 0;
    installmentOptions = result.installments
        .map((i) =>
            '${i.installmentQuantity} months: \$${i.installmentValue.toStringAsFixed(2)}')
        .join('\n');

    notifyListeners();
  }

  @override
  void dispose() {
    amountController.dispose();
    termController.dispose();
    super.dispose();
  }
}
