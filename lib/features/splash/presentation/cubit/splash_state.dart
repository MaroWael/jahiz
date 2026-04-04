import 'package:jahiz/features/splash/services/startup_route_service.dart';

const _noDestination = Object();
const _noError = Object();

class SplashState {
  const SplashState({
    this.isResolving = false,
    this.destination,
    this.errorMessage,
  });

  final bool isResolving;
  final StartupDestination? destination;
  final String? errorMessage;

  SplashState copyWith({
    bool? isResolving,
    Object? destination = _noDestination,
    Object? errorMessage = _noError,
  }) {
    return SplashState(
      isResolving: isResolving ?? this.isResolving,
      destination: destination == _noDestination
          ? this.destination
          : destination as StartupDestination?,
      errorMessage: errorMessage == _noError
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
