import '../models/inspection_model.dart';

abstract class IInspectionRepository {
  Future<InspectionModel> createInspection(InspectionModel inspection);
  Future<InspectionModel?> getInspectionById(String id);
  Future<List<InspectionModel>> getInspectionsForApplication(String applicationId);
  Future<List<InspectionModel>> getInspectionHistoryForInstrument(String instrumentId);
  Future<InspectionModel> updateInspection(InspectionModel inspection);
  Future<InspectionModel> submitInspection(String inspectionId);
}
