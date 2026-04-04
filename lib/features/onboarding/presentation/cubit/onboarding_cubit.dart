import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/core/services/app_preferences_service.dart';

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit({AppPreferencesService? appPreferencesService})
    : _appPreferencesService = appPreferencesService ?? AppPreferencesService(),
      super(0);

  final AppPreferencesService _appPreferencesService;

  void changePage(int index) => emit(index);

  void nextPage(int total) {
    if (state < total - 1) emit(state + 1);
  }

  bool isLastPage(int total) => state == total - 1;

  Future<void> completeOnboarding() async {
    await _appPreferencesService.setSeenOnboarding(true);
  }
}
