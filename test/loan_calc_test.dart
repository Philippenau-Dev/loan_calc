import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calc/loan_cal.dart';
import 'package:xirr_flutter/xirr_flutter.dart';

void main() {
  LoanCalc loanCalc = LoanCalc(
    annualIOFTax: 0.38,
    dailyIOFRate: 0.0082,
    minPeriods: 5,
    maxPeriods: 15,
    monthlyInterestRate: 15.9,
    minimumInstallmentValue: 300,
    tacLimit: 250,
    tacRate: 12,
  );

  group('LoanCalc Tests', () {
    group('calculateTAC', () {
      const tacLimit = 250.0;
      const tacTax = 12.0;
      test('should calculate TAC correctly limited 250', () {
        const principalAmount = 5000.0;
        final tac = loanCalc.calculateTAC(principalAmount, tacTax, tacLimit);
        expect(tac, equals(250.0));
      });

      test('should calculate TAC correctly ', () {
        const principalAmount = 1000.0;
        const tacTax = 12.0;
        final tac = loanCalc.calculateTAC(principalAmount, tacTax, tacLimit);
        expect(tac, equals(120.0));
      });
    });

    group('calculateFixedIOF', () {
      test('should calculate fixed IOF correctly for a loan amount', () {
        const loanAmount = 1120.0;
        const annualIOFRate = 0.38;

        final fixedIOF = loanCalc.calculateFixedIOF(
          loanAmount: loanAmount,
          annualIOFRate: annualIOFRate,
        );

        expect(
          fixedIOF,
          closeTo(4.26, 0.01),
        );
      });

      test('should calculate fixed IOF as 0 when loan amount is 0', () {
        const loanAmount = 0.0;
        const annualIOFRate = 0.38;

        final fixedIOF = loanCalc.calculateFixedIOF(
          loanAmount: loanAmount,
          annualIOFRate: annualIOFRate,
        );

        expect(fixedIOF, equals(0.0));
      });

      test('should calculate fixed IOF correctly for different annual rates',
          () {
        const loanAmount = 5000.0;
        const annualIOFRate = 1.5;

        final fixedIOF = loanCalc.calculateFixedIOF(
          loanAmount: loanAmount,
          annualIOFRate: annualIOFRate,
        );

        expect(fixedIOF, equals(75.0));
      });

      test('should return correct fixed IOF when rate is 0', () {
        const loanAmount = 2000.0;
        const annualIOFRate = 0.0;

        final fixedIOF = loanCalc.calculateFixedIOF(
          loanAmount: loanAmount,
          annualIOFRate: annualIOFRate,
        );

        expect(fixedIOF, equals(0.0));
      });
    });

    group('calculateDailyIOF Tests', () {
      test('should calculate daily IOF correctly for valid days', () {
        const vp = 10000.0;
        const dailyIOFRate = 0.0082;
        const days = 30;

        final dailyIOF = loanCalc.calculateDailyIOF(
          vp: vp,
          dailyIOFRate: dailyIOFRate,
          days: days,
        );

        const expectedIOF = vp * days * (dailyIOFRate / 100);
        expect(dailyIOF, equals(expectedIOF));
      });

      test('should calculate daily IOF correctly when days is greater than 365',
          () {
        const vp = 173.0;
        const dailyIOFRate = 0.0082;
        const days = 470;

        final dailyIOF = loanCalc.calculateDailyIOF(
          vp: vp,
          dailyIOFRate: dailyIOFRate,
          days: days,
        );

        const expectedIOF = vp * 365 * (dailyIOFRate / 100);
        expect(dailyIOF, equals(expectedIOF));
      });

      test('should return 0 when loan amount (vp) is 0', () {
        const vp = 0.0;
        const dailyIOFRate = 0.0082;
        const days = 30;

        final dailyIOF = loanCalc.calculateDailyIOF(
          vp: vp,
          dailyIOFRate: dailyIOFRate,
          days: days,
        );

        expect(dailyIOF, equals(0.0));
      });

      test('should return 0 when daily IOF rate is 0', () {
        const vp = 10000.0;
        const dailyIOFRate = 0.0;
        const days = 30;

        final dailyIOF = loanCalc.calculateDailyIOF(
          vp: vp,
          dailyIOFRate: dailyIOFRate,
          days: days,
        );

        expect(dailyIOF, equals(0.0));
      });

      test('should calculate daily IOF correctly for 1 day', () {
        const vp = 10000.0;
        const dailyIOFRate = 0.0082;
        const days = 1;

        final dailyIOF = loanCalc.calculateDailyIOF(
          vp: vp,
          dailyIOFRate: dailyIOFRate,
          days: days,
        );

        const expectedIOF = vp * days * (dailyIOFRate / 100);
        expect(dailyIOF, equals(expectedIOF));
      });
    });

    group('pmtAdjusted', () {
      test('should calculate adjusted PMT correctly', () {
        const monthlyInterestRate = 1.5;
        const periods = 12;
        const loanAmount = 10000.0;
        const differenceInDays = 45;

        final adjustedPMT = loanCalc.pmtAdjusted(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          loanAmount: loanAmount,
          differenceInDays: differenceInDays,
        );

        const rate = monthlyInterestRate / 100;
        final pmt = (loanAmount * rate) / (1 - pow(1 + rate, -periods));
        final adjustmentFactor =
            pmt * pow(1 + rate, (differenceInDays - 30) / 30);

        expect(adjustedPMT, equals(adjustmentFactor.abs()));
      });

      test(
          'should return positive PMT adjustment even when the adjustment factor is negative',
          () {
        const monthlyInterestRate = 2.0;
        const periods = 24;
        const loanAmount = 15000.0;
        const differenceInDays = 15;

        final adjustedPMT = loanCalc.pmtAdjusted(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          loanAmount: loanAmount,
          differenceInDays: differenceInDays,
        );

        expect(adjustedPMT, greaterThan(0));
      });

      test('should return the same PMT when differenceInDays is 30', () {
        const monthlyInterestRate = 1.0;
        const periods = 12;
        const loanAmount = 5000.0;
        const differenceInDays = 30;

        final adjustedPMT = loanCalc.pmtAdjusted(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          loanAmount: loanAmount,
          differenceInDays: differenceInDays,
        );

        const rate = monthlyInterestRate / 100;
        final pmt = (loanAmount * rate) / (1 - pow(1 + rate, -periods));
        expect(adjustedPMT, equals(pmt));
      });

      test('should calculate adjusted PMT correctly for a high interest rate',
          () {
        const monthlyInterestRate = 10.0;
        const periods = 6;
        const loanAmount = 2000.0;
        const differenceInDays = 90;

        final adjustedPMT = loanCalc.pmtAdjusted(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          loanAmount: loanAmount,
          differenceInDays: differenceInDays,
        );

        const rate = monthlyInterestRate / 100;
        final pmt = (loanAmount * rate) / (1 - pow(1 + rate, -periods));
        final adjustmentFactor =
            pmt * pow(1 + rate, (differenceInDays - 30) / 30);

        expect(adjustedPMT, equals(adjustmentFactor.abs()));
      });

      test('should return 0 if loanAmount is 0', () {
        const monthlyInterestRate = 1.5;
        const periods = 12;
        const loanAmount = 0.0;
        const differenceInDays = 30;

        final adjustedPMT = loanCalc.pmtAdjusted(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          loanAmount: loanAmount,
          differenceInDays: differenceInDays,
        );

        expect(adjustedPMT, equals(0.0));
      });
    });

    group('calculateInstallment', () {
      test('should calculate installment correctly for valid inputs', () {
        const monthlyInterestRate = 1.5;
        const periods = 12;
        const financedAmount = 10000.0;

        final installment = loanCalc.calculateInstallment(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          financedAmount: financedAmount,
        );

        const rate = monthlyInterestRate / 100;
        final expectedInstallment =
            (financedAmount * rate) / (1 - pow(1 + rate, -periods));

        expect(installment, equals(expectedInstallment.abs()));
      });

      test('should return 0 when financed amount is 0', () {
        const monthlyInterestRate = 1.5;
        const periods = 12;
        const financedAmount = 0.0;

        final installment = loanCalc.calculateInstallment(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          financedAmount: financedAmount,
        );

        expect(installment, equals(0.0));
      });

      test('should return correct installment for a higher interest rate', () {
        const monthlyInterestRate = 5.0;
        const periods = 24;
        const financedAmount = 5000.0;

        final installment = loanCalc.calculateInstallment(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          financedAmount: financedAmount,
        );

        const rate = monthlyInterestRate / 100;
        final expectedInstallment =
            (financedAmount * rate) / (1 - pow(1 + rate, -periods));

        expect(installment, equals(expectedInstallment.abs()));
      });

      test('should return correct installment for a large loan amount', () {
        const monthlyInterestRate = 2.0;
        const periods = 36;
        const financedAmount = 50000.0;

        final installment = loanCalc.calculateInstallment(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          financedAmount: financedAmount,
        );

        const rate = monthlyInterestRate / 100;
        final expectedInstallment =
            (financedAmount * rate) / (1 - pow(1 + rate, -periods));

        expect(installment, equals(expectedInstallment.abs()));
      });

      test(
          'should return the same installment for the same financed amount and interest rate',
          () {
        const monthlyInterestRate = 3.0;
        const periods = 24;
        const financedAmount = 15000.0;

        final installment1 = loanCalc.calculateInstallment(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          financedAmount: financedAmount,
        );

        final installment2 = loanCalc.calculateInstallment(
          monthlyInterestRate: monthlyInterestRate,
          periods: periods,
          financedAmount: financedAmount,
        );

        expect(installment1, equals(installment2));
      });
    });

    group('xirr', () {
      test('should calculate XIRR correctly for valid transactions', () {
        final transactions = [
          Transaction(-1000.0, DateTime(2023, 1, 1)),
          Transaction(500.0, DateTime(2023, 6, 1)),
          Transaction(550.0, DateTime(2024, 1, 1)),
        ];

        final xirrResult = loanCalc.xirr(transactions: transactions);

        expect(xirrResult, greaterThan(0));
      });

      test('should return 0 if no valid XIRR is found after maxGuess attempts',
          () {
        final transactions = [
          Transaction(-1000.0, DateTime(2023, 1, 1)),
          Transaction(1000.0, DateTime(2024, 1, 1)),
        ];

        final xirrResult = loanCalc.xirr(transactions: transactions);

        expect(xirrResult, equals(0));
      });

      test('should handle empty transactions list gracefully', () {
        final transactions = <Transaction>[];

        final xirrResult = loanCalc.xirr(transactions: transactions);

        expect(xirrResult, equals(0));
      });

      test(
          'should calculate XIRR correctly for transactions with equal amounts and dates',
          () {
        final transactions = [
          Transaction(-1000.0, DateTime(2023, 1, 1)),
          Transaction(1000.0, DateTime(2023, 6, 1)),
        ];

        final xirrResult = loanCalc.xirr(transactions: transactions);

        expect(
          xirrResult,
          closeTo(0, 1e-10),
        ); // Verifica se o valor está próximo de 0 com uma precisão de 10 casas decimais
      });

      test('should throw no exception on invalid transactions', () {
        final transactions = [
          Transaction(1000.0, DateTime(2023, 1, 1)),
        ];

        expect(
            () => loanCalc.xirr(transactions: transactions), returnsNormally);
      });

      test('should return correct XIRR for multiple transactions over a year',
          () {
        final transactions = [
          Transaction(-5000.0, DateTime(2023, 1, 1)),
          Transaction(2000.0, DateTime(2023, 6, 1)),
          Transaction(2000.0, DateTime(2023, 12, 31)),
          Transaction(1500.0, DateTime(2024, 6, 1)),
        ];

        final xirrResult = loanCalc.xirr(transactions: transactions);

        expect(xirrResult, greaterThan(0));
      });
    });

    group('calculateVP', () {
      test(
          'should calculate VP correctly for positive xirr and differenceInDays',
          () {
        const pmt = 1000.0;
        const xirr = 0.05;
        const differenceInDays = 365;

        final vp = loanCalc.calculateVP(
            pmt: pmt, xirr: xirr, differenceInDays: differenceInDays);

        expect(vp, closeTo(952.39, 0.01));
      });

      test('should calculate VP correctly for zero xirr', () {
        const pmt = 1000.0;
        const xirr = 0.0;
        const differenceInDays = 365;

        final vp = loanCalc.calculateVP(
            pmt: pmt, xirr: xirr, differenceInDays: differenceInDays);

        expect(vp, equals(1000.0));
      });

      test('should calculate VP correctly for small payment amount', () {
        const pmt = 50.0;
        const xirr = 0.05;
        const differenceInDays = 365;

        final vp = loanCalc.calculateVP(
            pmt: pmt, xirr: xirr, differenceInDays: differenceInDays);

        expect(vp, closeTo(47.62, 0.01));
      });
    });

    group('calculateDateAndDayDifference', () {
      test(
          'should calculate day difference correctly for two dates in the same year',
          () {
        final lastDate = DateTime(2023, 1, 1);
        final currentDate = DateTime(2023, 1, 10);

        final dayDifference = loanCalc.calculateDateAndDayDifference(
            lastDate: lastDate, currentDate: currentDate);

        expect(dayDifference, equals(9));
      });

      test(
          'should calculate day difference correctly for two dates across different years',
          () {
        final lastDate = DateTime(2023, 12, 31);
        final currentDate = DateTime(2024, 1, 1);

        final dayDifference = loanCalc.calculateDateAndDayDifference(
            lastDate: lastDate, currentDate: currentDate);

        expect(dayDifference, equals(1));
      });

      test(
          'should calculate day difference correctly for dates with negative difference',
          () {
        final lastDate = DateTime(2023, 1, 10);
        final currentDate = DateTime(2023, 1, 1);

        final dayDifference = loanCalc.calculateDateAndDayDifference(
            lastDate: lastDate, currentDate: currentDate);

        expect(dayDifference, equals(9));
      });

      test('should calculate day difference correctly for same date', () {
        final lastDate = DateTime(2023, 1, 1);
        final currentDate = DateTime(2023, 1, 1);

        final dayDifference = loanCalc.calculateDateAndDayDifference(
            lastDate: lastDate, currentDate: currentDate);

        expect(dayDifference, equals(0));
      });

      test('should calculate day difference correctly for dates with large gap',
          () {
        final lastDate = DateTime(2020, 1, 1);
        final currentDate = DateTime(2023, 1, 1);

        final dayDifference = loanCalc.calculateDateAndDayDifference(
            lastDate: lastDate, currentDate: currentDate);

        expect(dayDifference, equals(1096));
      });
    });

    group('generateInstallment Tests', () {
      test('should generate correct installment for valid inputs', () {
        const monthlyInterestRate = 15.9;
        const financedAmount = 1120.0;
        const desiredValue = 1000.0;
        const dailyIOFRate = 0.0082;
        final fixedIOF = loanCalc.calculateFixedIOF(
          annualIOFRate: 0.38,
          loanAmount: 1120.0,
        );
        final tac = loanCalc.calculateTAC(
          desiredValue,
          12,
          250,
        );
        const differenceInDays = 45;
        const periods = 5;
        const maxPeriods = 15;

        final installment = loanCalc.generateInstallment(
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

        expect(installment.installmentQuantity, equals(periods));
        expect(installment.installmentValue, isNotNull);
        expect(installment.financedAmount, isNotNull);
        expect(installment.financedAmount, closeTo(1133.30, 0.01));
        expect(installment.principalAmount, equals(desiredValue));
        expect(installment.tac, equals(tac));
        expect(installment.iof, isNotNull);
      });

      test(
          'should generate installment with correct financed amount calculation',
          () {
        const monthlyInterestRate = 2.0;
        const financedAmount = 7000.0;
        const desiredValue = 7000.0;
        const dailyIOFRate = 0.0085;
        const fixedIOF = 70.0;
        const tac = 150.0;
        const differenceInDays = 45;
        const periods = 18;
        const maxPeriods = 30;

        final installment = loanCalc.generateInstallment(
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

        expect(installment.financedAmount, greaterThan(financedAmount));
      });

      test('should handle edge case with minimal periods and amounts', () {
        const monthlyInterestRate = 0.5;
        const financedAmount = 1000.0;
        const desiredValue = 1000.0;
        const dailyIOFRate = 0.005;
        const fixedIOF = 20.0;
        const tac = 30.0;
        const differenceInDays = 60;
        const periods = 5;
        const maxPeriods = 10;

        final installment = loanCalc.generateInstallment(
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

        expect(installment.installmentQuantity, equals(periods));
        expect(installment.installmentValue, isNotNull);
      });

      test('should return valid results when tac is zero', () {
        const monthlyInterestRate = 1.2;
        const financedAmount = 2000.0;
        const desiredValue = 2000.0;
        const dailyIOFRate = 0.007;
        const fixedIOF = 40.0;
        const tac = 0.0;
        const differenceInDays = 90;
        const periods = 6;
        const maxPeriods = 12;

        final installment = loanCalc.generateInstallment(
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

        expect(installment.tac, equals(0.0));
      });

      test(
          'should calculate installment correctly when difference in days is large',
          () {
        const monthlyInterestRate = 1.8;
        const financedAmount = 3000.0;
        const desiredValue = 3000.0;
        const dailyIOFRate = 0.009;
        const fixedIOF = 30.0;
        const tac = 50.0;
        const differenceInDays = 120;
        const periods = 15;
        const maxPeriods = 24;

        final installment = loanCalc.generateInstallment(
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

        expect(installment.installmentValue, isNotNull);
        expect(installment.financedAmount, greaterThan(financedAmount));
      });
    });

    group('generateInstallmentList', () {
      test('should generate list of installments for valid inputs', () {
        const minimumInstallmentValue = 200.0;
        const desiredValue = 5000.0;
        const differenceInDays = 30;

        loanCalc = LoanCalc(
          annualIOFTax: 0.38,
          dailyIOFRate: 0.0082,
          minPeriods: 5,
          maxPeriods: 24,
          monthlyInterestRate: 1.5,
          minimumInstallmentValue: minimumInstallmentValue,
          tacLimit: 200,
          tacRate: 5,
        );

        final result = loanCalc.generateInstallmentList(
          desiredValue: desiredValue,
          differenceInDays: differenceInDays,
        );

        expect(result.installments, isNotEmpty);
        expect(result.selectedInstallment, isNotNull);
        expect(result.installments.first.installmentValue,
            greaterThan(minimumInstallmentValue));
      });

      test('should return empty installments when no valid installment found',
          () {
        const minimumInstallmentValue = 10000.0;
        const desiredValue = 5000.0;
        const differenceInDays = 30;

        loanCalc = LoanCalc(
          annualIOFTax: 0.38,
          dailyIOFRate: 0.0082,
          minPeriods: 6,
          maxPeriods: 12,
          monthlyInterestRate: 1.5,
          minimumInstallmentValue: minimumInstallmentValue,
          tacLimit: 200,
          tacRate: 5,
        );

        final result = loanCalc.generateInstallmentList(
          desiredValue: desiredValue,
          differenceInDays: differenceInDays,
        );

        expect(result.installments, isEmpty);
        expect(result.selectedInstallment, isNull);
      });

      test(
          'should include installment values greater than or equal to minimum installment value',
          () {
        const minimumInstallmentValue = 150.0;
        const desiredValue = 4000.0;
        const differenceInDays = 60;

        loanCalc = LoanCalc(
          annualIOFTax: 0.35,
          dailyIOFRate: 0.0075,
          minPeriods: 6,
          maxPeriods: 12,
          monthlyInterestRate: 2.0,
          minimumInstallmentValue: minimumInstallmentValue,
          tacLimit: 150.0,
          tacRate: 4.0,
        );

        final result = loanCalc.generateInstallmentList(
          desiredValue: desiredValue,
          differenceInDays: differenceInDays,
        );

        expect(result.installments, isNotEmpty);
        expect(
            result.installments.every((installment) =>
                installment.installmentValue >= minimumInstallmentValue),
            isTrue);
      });

      test('should return valid selectedInstallment if installments are found',
          () {
        const minimumInstallmentValue = 200.0;
        const desiredValue = 6000.0;
        const differenceInDays = 45;

        loanCalc = LoanCalc(
          annualIOFTax: 0.40,
          dailyIOFRate: 0.008,
          minPeriods: 6,
          maxPeriods: 12,
          monthlyInterestRate: 1.8,
          minimumInstallmentValue: minimumInstallmentValue,
          tacLimit: 250.0,
          tacRate: 6.0,
        );

        final result = loanCalc.generateInstallmentList(
          desiredValue: desiredValue,
          differenceInDays: differenceInDays,
        );

        expect(result.selectedInstallment, isNotNull);
      });

      test('should calculate tac correctly and adjust financedAmount', () {
        const minimumInstallmentValue = 1000.0;
        const desiredValue = 8000.0;
        const differenceInDays = 30;

        loanCalc = LoanCalc(
          annualIOFTax: 0.38,
          dailyIOFRate: 0.0082,
          minPeriods: 6,
          maxPeriods: 24,
          monthlyInterestRate: 1.8,
          minimumInstallmentValue: minimumInstallmentValue,
          tacLimit: 500.0,
          tacRate: 5.0,
        );

        final result = loanCalc.generateInstallmentList(
          desiredValue: desiredValue,
          differenceInDays: differenceInDays,
        );

        expect(result.installments, isNotEmpty);
        expect(result.installments.first.financedAmount,
            greaterThan(desiredValue));
      });
    });
  });
}
