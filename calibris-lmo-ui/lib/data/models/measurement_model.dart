class MeasurementModel {
  final String id;
  final String inspectionId;
  final String paramName;
  final String unit;
  final double expected;
  final double actual;
  final double tolerance;
  final bool withinTolerance;
  final String? notes;

  const MeasurementModel({
    required this.id,
    required this.inspectionId,
    required this.paramName,
    required this.unit,
    required this.expected,
    required this.actual,
    required this.tolerance,
    required this.withinTolerance,
    this.notes,
  });

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      id: json['id'],
      inspectionId: json['inspectionId'],
      paramName: json['paramName'],
      unit: json['unit'],
      expected: json['expected'],
      actual: json['actual'],
      tolerance: json['tolerance'],
      withinTolerance: json['withinTolerance'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'inspectionId': inspectionId,
    'paramName': paramName,
    'unit': unit,
    'expected': expected,
    'actual': actual,
    'tolerance': tolerance,
    'withinTolerance': withinTolerance,
    'notes': notes,
  };
}
