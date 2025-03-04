import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:loan_calc/src/entity/generated_installments_entity.dart';
import 'package:loan_calc/src/entity/installment_entity.dart';
import 'package:xirr_flutter/xirr_flutter.dart';

class LoanCalc {
  LoanCalc({
    required this.minimumInstallmentValue,
    required this.monthlyInterestRate,
    required this.tacRate,
    required this.tacLimit,
    required this.annualIOFTax,
    required this.dailyIOFRate,
    required this.minPeriods,
    required this.maxPeriods,
  });

  factory LoanCalc.empty() => LoanCalc(
        minimumInstallmentValue: 0,
        monthlyInterestRate: 0,
        tacRate: 0,
        tacLimit: 0,
        annualIOFTax: 0,
        dailyIOFRate: 0,
        minPeriods: 0,
        maxPeriods: 0,
      );

  final double minimumInstallmentValue;
  final double monthlyInterestRate;
  final double tacRate;
  final double tacLimit;
  final double annualIOFTax;
  final double dailyIOFRate;
  final int minPeriods;
  final int maxPeriods;

  // Calcula o TAC (Taxa de Abertura de Crédito)
  double calculateTAC(
    double principalAmount,
    double tacPercentage,
    double tacLimit,
  ) {
    final tac = principalAmount * (tacPercentage / 100);
    return tac <= tacLimit ? tac : tacLimit;
  }

  // Calcula o IOF total considerando o fixo e o diário
  double calculateTotalIOF({
    required double fixedIOF,
    required List<double> dailyIOFRates,
    required double loanAmount,
  }) {
    double totalIOF = fixedIOF + dailyIOFRates.fold(0, (sum, iof) => sum + iof);
    totalIOF = totalIOF / (loanAmount - totalIOF) * loanAmount;

    return totalIOF;
  }

  // Calcula o IOF fixo
  double calculateFixedIOF({
    required double loanAmount,
    required double annualIOFRate,
  }) {
    return loanAmount * (annualIOFRate / 100);
  }

  // Calcula o IOF diário
  double calculateDailyIOF({
    required double vp,
    required double dailyIOFRate,
    required int days,
  }) {
    days = days > 365 ? 365 : days;
    return vp * days * (dailyIOFRate / 100);
  }

  double pmtAdjusted({
    required double monthlyInterestRate,
    required int periods,
    required double loanAmount,
    required int differenceInDays,
  }) {
    final rate = monthlyInterestRate / 100;

    final pmt = (loanAmount * rate) / (1 - pow(1 + rate, -periods));

    final adjustmentFactor = pmt * pow(1 + rate, (differenceInDays - 30) / 30);

    return adjustmentFactor.abs();
  }

  double calculateInstallment({
    required double monthlyInterestRate,
    required int periods,
    required double financedAmount,
  }) {
    final rate = monthlyInterestRate / 100;

    final pmt = (financedAmount * rate) / (1 - pow(1 + rate, -periods));

    return pmt.abs();
  }

  // Cálculo do XIRR (Taxa Interna de Retorno Anualizada
  double xirr({
    required List<Transaction> transactions,
  }) {
    double guess = 1;
    const maxGuess = 5;

    while (guess <= maxGuess) {
      try {
        final xirr = XirrFlutter.withTransactionsAndGuess(transactions, guess)
            .calculate();

        if (xirr != null) {
          return xirr;
        }
      } on Exception catch (e) {
        debugPrint('Erro ao tentar o palpite $guess: $e');
      }

      guess += 1;
    }
    return 0;
  }

  //Gera lista de transações
  List<Transaction> generateTransactions({
    required double installmentAmount,
    required double pmt,
    required int numberOfPayments,
    required int maxPeriods,
    required int differenceInDays,
  }) {
    List<Transaction> transactions = [];

    DateTime startDate = DateTime.now();

    transactions.add(
      Transaction(-installmentAmount, startDate),
    );

    for (int i = 1; i <= maxPeriods; i++) {
      if (i <= numberOfPayments) {
        DateTime paymentDate = startDate;

        if (i == 1) {
          paymentDate = startDate.add(
            Duration(days: differenceInDays),
          );
        } else {
          paymentDate = startDate.add(
            Duration(
              days: differenceInDays + 30 * (i - 1),
            ),
          );
        }

        paymentDate = DateTime(
          paymentDate.year,
          paymentDate.month,
          startDate
              .add(
                Duration(days: differenceInDays),
              )
              .day,
          0,
          0,
          0,
        );

        transactions.add(Transaction(pmt, paymentDate));
      }
    }
    return transactions;
  }

  // Cálculo do Valor Presente (VP)
  double calculateVP({
    required double pmt,
    required double xirr,
    required int differenceInDays,
  }) {
    final xirrDailyRate = (pow(1 + xirr, 1 / 365) - 1) * 100;

    final result = pmt / pow(1 + (xirrDailyRate / 100), differenceInDays);
    return result;
  }

  // Calcula o valor do emprestimo
  double calculateFinancedBalance({
    required double totalIOF,
    required double tac,
    required double desiredValue,
  }) {
    return totalIOF + tac + desiredValue;
  }

  // Cálculo da lista de parcelas
  GeneratedInstallmentsEntity generateInstallmentList({
    required int differenceInDays,
    required double desiredValue,
  }) {
    final installments = <InstallmentEntity>[];

    final tac = calculateTAC(
      desiredValue,
      tacRate,
      tacLimit,
    );

    double financedAmount = desiredValue + tac;

    final fixedIOF = calculateFixedIOF(
      loanAmount: financedAmount,
      annualIOFRate: annualIOFTax,
    );

    for (int periods = minPeriods; periods <= maxPeriods; periods++) {
      final installment = generateInstallment(
        monthlyInterestRate: monthlyInterestRate,
        financedAmount: financedAmount,
        desiredValue: desiredValue,
        dailyIOFRate: dailyIOFRate,
        fixedIOF: fixedIOF,
        tac: tac,
        differenceInDays: differenceInDays,
        periods: periods,
        maxPeriods: maxPeriods,
      );

      if (installment.installmentValue >= minimumInstallmentValue) {
        installments.add(installment);
      } else {
        break;
      }
    }

    final selectedInstallment =
        installments.isNotEmpty ? installments.first : null;

    return GeneratedInstallmentsEntity(
      installments: installments,
      selectedInstallment: selectedInstallment,
    );
  }

  // Cálculo do valor da parcela
  InstallmentEntity generateInstallment({
    required double monthlyInterestRate,
    required double financedAmount,
    required double desiredValue,
    required double dailyIOFRate,
    required double fixedIOF,
    required double tac,
    required int differenceInDays,
    required int periods,
    required int maxPeriods,
  }) {
    final dailyIOFRates = <double>[];

    double pmt = pmtAdjusted(
      monthlyInterestRate: monthlyInterestRate,
      periods: periods,
      loanAmount: financedAmount,
      differenceInDays: differenceInDays,
    );

    final transactions = generateTransactions(
      pmt: pmt,
      installmentAmount: financedAmount,
      numberOfPayments: periods,
      differenceInDays: differenceInDays,
      maxPeriods: maxPeriods,
    );

    final xirrResult = xirr(
      transactions: transactions,
    );

    int days = 0;
    for (int i = 1; i < transactions.length; i++) {
      if (transactions[i].amount == 0.0) break;
      days = i == 1
          ? differenceInDays
          : days +
              calculateDateAndDayDifference(
                lastDate: transactions[i - 1].when,
                currentDate: transactions[i].when,
              );

      final vp = calculateVP(
        pmt: pmt,
        xirr: xirrResult,
        differenceInDays: days,
      );

      final dailyIOF = calculateDailyIOF(
        vp: vp,
        dailyIOFRate: dailyIOFRate,
        days: days,
      );
      dailyIOFRates.add(dailyIOF);
    }

    final totalIOF = calculateTotalIOF(
      fixedIOF: fixedIOF,
      dailyIOFRates: dailyIOFRates,
      loanAmount: financedAmount,
    );

    financedAmount = calculateFinancedBalance(
      totalIOF: totalIOF,
      tac: tac,
      desiredValue: desiredValue,
    );

    final installment = calculateInstallment(
      monthlyInterestRate: monthlyInterestRate,
      periods: periods,
      financedAmount: financedAmount,
    );

    return InstallmentEntity(
      installmentQuantity: periods,
      installmentValue: installment,
      financedAmount: financedAmount,
      principalAmount: desiredValue,
      tac: tac,
      iof: totalIOF,
    );
  }

  // Calcula o número de dias entre duas datas
  int calculateDateAndDayDifference({
    required DateTime lastDate,
    required DateTime currentDate,
  }) {
    return lastDate.difference(currentDate).inDays.abs();
  }
}
