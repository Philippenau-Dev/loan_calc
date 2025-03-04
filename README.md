# LoanCalc - Biblioteca de Cálculo de Empréstimos

## 📌 Sobre o Projeto

O **LoanCalc** é uma biblioteca desenvolvida em Dart para auxiliar no cálculo de empréstimos, considerando diferentes taxas e variáveis. Ele permite calcular valores como TAC (Taxa de Abertura de Crédito), IOF, parcelas ajustadas e a taxa interna de retorno (XIRR).

## 🚀 Funcionalidades

- **Cálculo do TAC** (Taxa de Abertura de Crédito)
- **Cálculo do IOF** (fixo e diário)
- **Cálculo do valor das parcelas**
- **Cálculo do XIRR** (Taxa Interna de Retorno Anualizada)
- **Geração de uma lista de parcelas**
- **Geração de transações de pagamento**
- **Cálculo do Valor Presente (VP)**

## 📦 Instalação

Adicione a dependência ao seu projeto no `pubspec.yaml`:

```yaml
dependencies:
  loan_calc: ^1.0.0
```
 ou utilize o comando `pub`:
 
```bash
pub add loan_calc

```

## 📝 Uso

Importe a biblioteca no seu código:

```dart
import 'package:loan_calc/loan_calc.dart';
```

### 🔖 Cálculo do TAC

Para calcular o TAC, você precisa fornecer o valor do empréstimo, a taxa de juros e o limite de juros:

```dart
final tac = loanCalc.calculateTAC(principalAmount, tacTax, tacLimit);
```

### 🔖 Cálculo do IOF

Para calcular o IOF, você precisa fornecer o valor do empréstimo, a taxa de juros e o número de dias:

```dart
final iof = loanCalc.calculateFixedIOF(
  loanAmount: loanAmount,
  annualIOFRate: annualIOFRate,
);
```

### 🔖 Cálculo do valor das parcelas

Para calcular o valor das parcelas, você precisa fornecer o valor do empréstimo, a taxa de juros, o número de dias e o número de parcelas:

```dart
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
```

### 🔖 Cálculo do XIRR

Para calcular o XIRR, você precisa fornecer uma lista de transações:

```dart
final xirrResult = loanCalc.xirr(transactions: transactions);
```

### 🔖 Geração de uma lista de parcelas

Para gerar uma lista de parcelas, você precisa fornecer o valor do empréstimo, a taxa de juros, o número de dias, o número de parcelas máxima e o limite de juros:

```dart
final result = loanCalc.generateInstallmentList(
  desiredValue: desiredValue,
  differenceInDays: differenceInDays,
  annualIOFTax: 0.38,
  dailyIOFRate: 0.0082,
  minPeriods: 5,
  maxPeriods: 15,
  monthlyInterestRate: 15.9,
  minimumInstallmentValue: 300,
  tacLimit: 250,
  tacRate: 12,
);
```

### 🔖 Geração de transações de pagamento

Para gerar transações de pagamento, você precisa fornecer o valor do empréstimo, a taxa de juros e o número de dias:

```dart
final transactions = loanCalc.generateTransactions(
  pmt: pmt,
  installmentAmount: financedAmount,
  numberOfPayments: periods,
  differenceInDays: differenceInDays,
  maxPeriods: maxPeriods,
);
```

### 🔖 Cálculo do Valor Presente (VP)

Para calcular o valor presente, você precisa fornecer o valor do empréstimo, a taxa de juros e o número de dias:

```dart
final vp = loanCalc.calculateVP(
  pmt: pmt,
  xirr: xirrResult,
  differenceInDays: days,
);
```

## 📄 Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para obter detalhes.

## 📜 Contribuindo

Para contribuir com o projeto, siga os passos abaixo:

1. Fork o repositório.
2. Crie uma nova branch com um nome descritivo para sua alteração.
3. Faça as alterações necessárias.
4. Teste suas alterações com sucesso.
5. Envie um pull request para o repositório original.

Lembre-se de seguir as convenções de codificação e organização do projeto.

## 📝 Autores

- **Philippe Nau Rosa** - [Philippenau-Dev](https://github.com/Philippenau-Dev)


