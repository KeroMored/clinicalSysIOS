import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/emergency_repository.dart';
import 'emergency_state.dart';

class EmergencyCubit extends Cubit<EmergencyState> {
  final EmergencyRepository _repository;

  EmergencyCubit(this._repository) : super(EmergencyInitial());

  void loadEmergencyNumbers() {
    try {
      emit(EmergencyLoading());
      final numbers = _repository.getEmergencyNumbers();
      emit(EmergencyLoaded(numbers));
    } catch (e) {
      emit(EmergencyError('فشل في تحميل أرقام الطوارئ'));
    }
  }

  Future<void> makeCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        emit(const EmergencyError('لا يمكن إجراء المكالمة'));
      }
    } catch (e) {
      emit(EmergencyError('فشل في الاتصال: ${e.toString()}'));
    }
  }
}
