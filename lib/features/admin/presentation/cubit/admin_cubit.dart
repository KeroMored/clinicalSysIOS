import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/pharmacy_request_model.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository repository;

  AdminCubit(this.repository) : super(AdminInitial());

  // Load pending pharmacy requests
  Future<void> loadPendingPharmacyRequests() async {
    try {
      emit(AdminLoading());
      final requests = await repository.getPendingPharmacyRequests();
      emit(PharmacyRequestsLoaded(requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Load pharmacy requests by status
  Future<void> loadPharmacyRequestsByStatus(String status) async {
    try {
      emit(AdminLoading());
      final requests = await repository.getPharmacyRequestsByStatus(status);
      emit(PharmacyRequestsLoaded(requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Load all pharmacy requests
  Future<void> loadAllPharmacyRequests() async {
    try {
      emit(AdminLoading());
      final requests = await repository.getAllPharmacyRequests();
      emit(PharmacyRequestsLoaded(requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Load request details
  Future<void> loadRequestDetails(String requestId) async {
    try {
      emit(RequestDetailsLoading());
      final request = await repository.getRequestById(requestId);
      emit(RequestDetailsLoaded(request));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Approve pharmacy request
  Future<void> approveRequest(String requestId) async {
    try {
      emit(RequestApproving());
      await repository.approvePharmacyRequest(requestId);
      emit(RequestApproved('تم الموافقة على الطلب بنجاح'));
      // Reload requests
      await loadPendingPharmacyRequests();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Reject pharmacy request
  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      emit(RequestRejecting());
      await repository.rejectPharmacyRequest(requestId, reason);
      emit(RequestRejected('تم رفض الطلب'));
      // Reload requests
      await loadPendingPharmacyRequests();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Set pharmacy status to pending
  Future<void> setPendingRequest(String requestId) async {
    try {
      emit(RequestSettingToPending());
      await repository.setPendingPharmacyRequest(requestId);
      emit(RequestSetToPending('تم تغيير حالة الصيدلية إلى انتظار'));
      // Reload requests
      await loadPendingPharmacyRequests();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Submit new pharmacy request
  Future<void> submitPharmacyRequest(PharmacyRequestModel request) async {
    try {
      emit(RequestSubmitting());
      await repository.submitPharmacyRequest(request);
      emit(RequestSubmitted('تم إرسال الطلب بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ============ CLINIC REQUESTS ============

  // Load pending clinic requests
  Future<void> loadPendingClinicRequests() async {
    try {
      emit(AdminLoading());
      final requests = await repository.getPendingClinicRequests();
      emit(ClinicRequestsLoaded(requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Load clinic requests by status
  Future<void> loadClinicRequestsByStatus(String status) async {
    try {
      emit(AdminLoading());
      final requests = await repository.getClinicRequestsByStatus(status);
      emit(ClinicRequestsLoaded(requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Approve clinic request
  Future<void> approveClinicRequest(String clinicId) async {
    try {
      emit(RequestApproving());
      await repository.approveClinicRequest(clinicId);
      emit(RequestApproved('تم قبول العيادة بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Reject clinic request
  Future<void> rejectClinicRequest(String clinicId, String reason) async {
    try {
      emit(RequestRejecting());
      await repository.rejectClinicRequest(clinicId, reason);
      emit(RequestRejected('تم رفض العيادة'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Delete clinic
  Future<void> deleteClinic(String clinicId) async {
    try {
      emit(AdminLoading());
      await repository.deleteClinic(clinicId);
      emit(RequestApproved('تم حذف العيادة بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ============ LABORATORY FUNCTIONS ============

  // Get all laboratory requests
  void loadAllLaboratoryRequests() {
    emit(AdminLoading());
    repository.getAllLaboratoryRequests().listen(
      (laboratories) {
        emit(LaboratoryRequestsLoaded(laboratories));
      },
      onError: (error) {
        emit(AdminError(error.toString()));
      },
    );
  }

  // Get pending laboratory requests
  void loadPendingLaboratoryRequests() {
    emit(AdminLoading());
    repository.getPendingLaboratoryRequests().listen(
      (laboratories) {
        emit(LaboratoryRequestsLoaded(laboratories));
      },
      onError: (error) {
        emit(AdminError(error.toString()));
      },
    );
  }

  // Get laboratory requests by status
  void loadLaboratoryRequestsByStatus(String status) {
    emit(AdminLoading());
    repository
        .getLaboratoryRequestsByStatus(status)
        .listen(
          (laboratories) {
            emit(LaboratoryRequestsLoaded(laboratories));
          },
          onError: (error) {
            emit(AdminError(error.toString()));
          },
        );
  }

  // Approve laboratory request
  Future<void> approveLaboratoryRequest(String labId) async {
    try {
      await repository.approveLaboratoryRequest(labId);
      // Reload the current list
      loadPendingLaboratoryRequests();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Reject laboratory request
  Future<void> rejectLaboratoryRequest(String labId, String reason) async {
    try {
      await repository.rejectLaboratoryRequest(labId, reason);
      // Reload the current list
      loadPendingLaboratoryRequests();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Back laboratory to pending
  Future<void> backLaboratoryToPending(String labId) async {
    try {
      await repository.backLaboratoryToPending(labId);
      // Reload the current list
      loadLaboratoryRequestsByStatus('approved');
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Delete laboratory
  Future<void> deleteLaboratory(String labId) async {
    try {
      await repository.deleteLaboratory(labId);
      // Reload the current list
      loadPendingLaboratoryRequests();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ============ PHARMACY FUNCTIONS ============

  // Get pending count
  Future<int> getPendingCount() async {
    try {
      return await repository.getPendingPharmacyRequestsCount();
    } catch (e) {
      return 0;
    }
  }

  // Add pharmacy directly (from admin)
  Future<void> addPharmacyDirectly(PharmacyRequestModel request) async {
    try {
      emit(AdminLoading());
      // Add directly to pharmacies collection
      await repository.addPharmacyDirectly(request);
      emit(PharmacyAddedSuccessfully('تم إضافة الصيدلية بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ============ NURSING FUNCTIONS ============

  // Load pending nurse requests
  Future<void> loadPendingNurseRequests() async {
    try {
      emit(AdminLoading());
      final requests = await repository.getPendingNurseRequests();
      emit(NurseRequestsLoaded(requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Load nurse requests by status
  Future<void> loadNurseRequestsByStatus(String status) async {
    try {
      emit(AdminLoading());
      final requests = await repository.getNurseRequestsByStatus(status);
      emit(NurseRequestsLoaded(requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Approve nurse request
  Future<void> approveNurseRequest(String nurseId) async {
    try {
      await repository.approveNurseRequest(nurseId);
      emit(RequestApproved('تم قبول الطلب بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Reject nurse request
  Future<void> rejectNurseRequest(String nurseId, String reason) async {
    try {
      await repository.rejectNurseRequest(nurseId, reason);
      emit(RequestRejected('تم رفض الطلب'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Delete nurse request
  Future<void> deleteNurseRequest(String nurseId) async {
    try {
      await repository.deleteNurseRequest(nurseId);
      emit(RequestApproved('تم حذف الطلب بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Add nurse directly by admin
  Future<void> addNurse(dynamic nurse) async {
    try {
      await repository.addNurse(nurse);
      emit(NurseAdded('تمت إضافة الممرض بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // Add delivery directly by admin
  Future<void> addDelivery(dynamic delivery) async {
    try {
      await repository.addDelivery(delivery);
      emit(DeliveryAdded('تمت إضافة الديليفري بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> addRehabilitationCenter(dynamic center) async {
    try {
      await repository.addRehabilitationCenter(center);
      emit(RehabilitationCenterAdded('تمت إضافة مركز التأهيل بنجاح'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
