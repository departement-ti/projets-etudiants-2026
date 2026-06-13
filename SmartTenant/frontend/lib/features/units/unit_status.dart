enum UnitStatus { AVAILABLE, OCCUPIED, MAINTENANCE, RESERVED }

extension UnitStatusX on UnitStatus {
  String get value => name;

  static UnitStatus fromString(String value) {
    return UnitStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => UnitStatus.AVAILABLE,
    );
  }
}
