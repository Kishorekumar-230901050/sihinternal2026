import 'package:uuid/uuid.dart';
import 'i_inspection_repository.dart';
import '../models/inspection_model.dart';
import '../mock/mock_data.dart';

class MockInspectionRepository implements IInspectionRepository {
  final _uuid = const Uuid();

  @override
  Future<InspectionModel> createInspection(InspectionModel inspection) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newInspection = inspection.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    MockDataStore.inspections.add(newInspection);
    return newInspection;
  }

  @override
  Future<InspectionModel?> getInspectionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return MockDataStore.inspections.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<InspectionModel>> getInspectionsForApplication(String applicationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataStore.inspections.where((i) => i.applicationId == applicationId).toList();
  }

  @override
  Future<List<InspectionModel>> getInspectionHistoryForInstrument(String instrumentId) async {
    // In mock, we would map application to instrument, but we simplified it.
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataStore.inspections.toList();
  }

  @override
  Future<InspectionModel> updateInspection(InspectionModel inspection) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = MockDataStore.inspections.indexWhere((i) => i.id == inspection.id);
    if (index == -1) throw Exception('Inspection not found');
    
    MockDataStore.inspections[index] = inspection;
    return inspection;
  }

  @override
  Future<InspectionModel> submitInspection(String inspectionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = MockDataStore.inspections.indexWhere((i) => i.id == inspectionId);
    if (index == -1) throw Exception('Inspection not found');
    
    final inspection = MockDataStore.inspections[index].copyWith(
      submittedAt: DateTime.now(),
    );
    MockDataStore.inspections[index] = inspection;
    return inspection;
  }
}
