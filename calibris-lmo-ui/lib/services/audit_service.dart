import 'package:uuid/uuid.dart';
import '../data/models/audit_log_model.dart';
import '../data/mock/mock_data.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final _uuid = const Uuid();

  void log(String userId, AuditAction action, {String? entityId, String? entityType, String? details}) {
    final log = AuditLogModel(
      id: _uuid.v4(),
      userId: userId,
      action: action,
      entityId: entityId,
      entityType: entityType,
      timestamp: DateTime.now(),
      details: details,
    );
    MockDataStore.auditLogs.add(log);
  }

  List<AuditLogModel> getLogs({String? userId}) {
    if (userId != null) {
      return MockDataStore.auditLogs.where((l) => l.userId == userId).toList();
    }
    return MockDataStore.auditLogs.toList();
  }
}
