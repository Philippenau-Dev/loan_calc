import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:loan_calc/src/entity/generated_installments_entity.dart';
import 'package:loan_calc/src/entity/installment_entity.dart';
import 'package:xirr_flutter/xirr_flutter.dart';

/// A classe `LoanCalc` fornece métodos para cálculos financeiros relacionados a empréstimos,
/// incluindo TAC, IOF, parcelas, XIRR e outros cálculos financeiros.
class LoanCalc {
  LoanCalc();

  /// Calcula a Taxa de Abertura de Crédito (TAC) com base no valor principal,
  /// percentual da taxa e limite máximo.
  ///
  /// - [principalAmount]: Valor principal do empréstimo.
  /// - [tacPercentage]: Percentual da TAC.
  /// - [tacLimit]: Valor máximo permitido para a TAC.
  /// - Retorna: O valor da TAC, limitado ao valor máximo especificado.
  double calculateTAC(
    double principalAmount,
    double tacPercentage,
    double tacLimit,
  ) {
    final tac = principalAmount * (tacPercentage / 100);
    return tac <= tacLimit ? tac : tacLimit;
  }

  /// Calcula o valor total do IOF (Imposto sobre Operações Financeiras),
  /// considerando o IOF fixo e as taxas diárias.
  ///
  /// - [fixedIOF]: Valor do IOF fixo.
  /// - [dailyIOFRates]: Lista de taxas diárias de IOF.
  /// - [loanAmount]: Valor total do empréstimo.
  /// - Retorna: O valor total do IOF.
  double calculateTotalIOF({
    required double fixedIOF,
    required List<double> dailyIOFRates,
    required double loanAmount,
  }) {
    double totalIOF = fixedIOF + dailyIOFRates.fold(0, (sum, iof) => sum + iof);
    totalIOF = totalIOF / (loanAmount - totalIOF) * loanAmount;

    return totalIOF;
  }

  /// Calcula o valor do IOF fixo com base no valor do empréstimo e taxa anual.
  ///
  /// - [loanAmount]: Valor do empréstimo.
  /// - [annualIOFRate]: Taxa anual do IOF.
  /// - Retorna: O valor do IOF fixo.
  double calculateFixedIOF({
    required double loanAmount,
    required double annualIOFRate,
  }) {
    return loanAmount * (annualIOFRate / 100);
  }

  /// Calcula o valor do IOF diário com base no valor presente, taxa diária e número de dias.
  ///
  /// - [vp]: Valor presente.
  /// - [dailyIOFRate]: Taxa diária do IOF.
  /// - [days]: Número de dias.
  /// - Retorna: O valor do IOF diário, limitado a 365 dias.
  double calculateDailyIOF({
    required double vp,
    required double dailyIOFRate,
    required int days,
  }) {
    days = days > 365 ? 365 : days;
    return vp * days * (dailyIOFRate / 100);
  }

  /// Calcula o valor da parcela ajustada com base na taxa de juros mensal,
  /// número de períodos, valor do empréstimo e diferença de dias.
  ///
  /// - [monthlyInterestRate]: Taxa de juros mensal.
  /// - [periods]: Número de períodos.
  /// - [loanAmount]: Valor do empréstimo.
  /// - [differenceInDays]: Diferença de dias para ajuste.
  /// - Retorna: O valor da parcela ajustada.
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

  /// Calcula o valor da parcela com base na taxa de juros mensal,
  /// número de períodos e valor financiado.
  ///
  /// - [monthlyInterestRate]: Taxa de juros mensal.
  /// - [periods]: Número de períodos.
  /// - [financedAmount]: Valor financiado.
  /// - Retorna: O valor da parcela.
  double calculateInstallment({
    required double monthlyInterestRate,
    required int periods,
    required double financedAmount,
  }) {
    final rate = monthlyInterestRate / 100;

    final pmt = (financedAmount * rate) / (1 - pow(1 + rate, -periods));

    return pmt.abs();
  }

  /// Calcula a Taxa Interna de Retorno (XIRR) com base em uma lista de transações.
  ///
  /// - [transactions]: Lista de transações financeiras.
  /// - Retorna: A taxa interna de retorno anualizada.
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

  /// Gera uma lista de transações financeiras para cálculo do XIRR.
  ///
  /// - [installmentAmount]: Valor da parcela.
  /// - [pmt]: Valor do pagamento mensal.
  /// - [numberOfPayments]: Número de pagamentos.
  /// - [maxPeriods]: Número máximo de períodos.
  /// - [differenceInDays]: Diferença de dias para o primeiro pagamento.
  /// - Retorna: Lista de transações financeiras.
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

  /// Calcula o Valor Presente (VP) com base no pagamento mensal,
  /// taxa XIRR e diferença de dias.
  ///
  /// - [pmt]: Valor do pagamento mensal.
  /// - [xirr]: Taxa interna de retorno.
  /// - [differenceInDays]: Diferença de dias.
  /// - Retorna: O valor presente.
  double calculateVP({
    required double pmt,
    required double xirr,
    required int differenceInDays,
  }) {
    final xirrDailyRate = (pow(1 + xirr, 1 / 365) - 1) * 100;

    final result = pmt / pow(1 + (xirrDailyRate / 100), differenceInDays);
    return result;
  }

  /// Calcula o valor total financiado, incluindo IOF e TAC.
  ///
  /// - [totalIOF]: Valor total do IOF.
  /// - [tac]: Valor da TAC.
  /// - [desiredValue]: Valor desejado do empréstimo.
  /// - Retorna: O valor total financiado.
  double calculateFinancedBalance({
    required double totalIOF,
    required double tac,
    required double desiredValue,
  }) {
    return totalIOF + tac + desiredValue;
  }

  /// Gera uma lista de parcelas com base nos parâmetros fornecidos.
  ///
  /// - [differenceInDays]: Diferença de dias para o primeiro pagamento.
  /// - [desiredValue]: Valor desejado do empréstimo.
  /// - [minimumInstallmentValue]: Valor mínimo da parcela.
  /// - [monthlyInterestRate]: Taxa de juros mensal.
  /// - [tacRate]: Taxa de TAC.
  /// - [tacLimit]: Limite máximo da TAC.
  /// - [annualIOFTax]: Taxa anual do IOF.
  /// - [dailyIOFRate]: Taxa diária do IOF.
  /// - [minPeriods]: Número mínimo de períodos.
  /// - [maxPeriods]: Número máximo de períodos.
  /// - Retorna: Uma entidade contendo a lista de parcelas geradas.
  GeneratedInstallmentsEntity generateInstallmentList({
    required int differenceInDays,
    required double desiredValue,
    required double minimumInstallmentValue,
    required double monthlyInterestRate,
    required double tacRate,
    required double tacLimit,
    required double annualIOFTax,
    required double dailyIOFRate,
    required int minPeriods,
    required int maxPeriods,
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

  /// Gera uma entidade de parcela com base nos parâmetros fornecidos.
  ///
  /// - [monthlyInterestRate]: Taxa de juros mensal.
  /// - [financedAmount]: Valor financiado.
  /// - [desiredValue]: Valor desejado do empréstimo.
  /// - [dailyIOFRate]: Taxa diária do IOF.
  /// - [fixedIOF]: Valor do IOF fixo.
  /// - [tac]: Valor da TAC.
  /// - [differenceInDays]: Diferença de dias para o primeiro pagamento.
  /// - [periods]: Número de períodos.
  /// - [maxPeriods]: Número máximo de períodos.
  /// - Retorna: Uma entidade de parcela.
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

  /// Calcula a diferença de dias entre duas datas.
  ///
  /// - [lastDate]: Data inicial.
  /// - [currentDate]: Data final.
  /// - Retorna: A diferença de dias em valor absoluto.
  int calculateDateAndDayDifference({
    required DateTime lastDate,
    required DateTime currentDate,
  }) {
    return lastDate.difference(currentDate).inDays.abs();
  }
}
