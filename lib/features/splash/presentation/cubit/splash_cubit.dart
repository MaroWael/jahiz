import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/splash/presentation/cubit/splash_state.dart';
import 'package:jahiz/features/splash/services/startup_route_service.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit({StartupRouteService? startupRouteService})
    : _startupRouteService = startupRouteService ?? StartupRouteService(),
      super(const SplashState());

  final StartupRouteService _startupRouteService;

  Future<void> resolveDestination() async {
    emit(state.copyWith(isResolving: true, errorMessage: null));

    try {
      final destination = await _startupRouteService.resolveDestination();
      emit(
        state.copyWith(
          isResolving: false,
          destination: destination,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isResolving: false,
          destination: StartupDestination.auth,
          errorMessage: 'Unable to resolve startup route.',
        ),
      );
    }
  }
}
