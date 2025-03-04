class InstallmentEntity {
  const InstallmentEntity({
    required this.installmentQuantity,
    required this.installmentValue,
    required this.financedAmount,
    required this.principalAmount,
    required this.tac,
    required this.iof,
  });

  factory InstallmentEntity.empty() => InstallmentEntity(
        installmentQuantity: 0,
        installmentValue: 0,
        financedAmount: 0,
        principalAmount: 0,
        tac: 0,
        iof: 0,
      );

  final int installmentQuantity;
  final double installmentValue;
  final double financedAmount;
  final double principalAmount;
  final double tac;
  final double iof;
}
