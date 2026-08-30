class PhotoEvidenceModel {
  final String id;
  final String inspectionId;
  final String officerId;
  final String localPath;
  final String? caption;
  final double? gpsLat;
  final double? gpsLng;
  final DateTime takenAt;

  const PhotoEvidenceModel({
    required this.id,
    required this.inspectionId,
    required this.officerId,
    required this.localPath,
    this.caption,
    this.gpsLat,
    this.gpsLng,
    required this.takenAt,
  });

  factory PhotoEvidenceModel.fromJson(Map<String, dynamic> json) {
    return PhotoEvidenceModel(
      id: json['id'],
      inspectionId: json['inspectionId'],
      officerId: json['officerId'],
      localPath: json['localPath'],
      caption: json['caption'],
      gpsLat: json['gpsLat'],
      gpsLng: json['gpsLng'],
      takenAt: DateTime.parse(json['takenAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'inspectionId': inspectionId,
    'officerId': officerId,
    'localPath': localPath,
    'caption': caption,
    'gpsLat': gpsLat,
    'gpsLng': gpsLng,
    'takenAt': takenAt.toIso8601String(),
  };
}
