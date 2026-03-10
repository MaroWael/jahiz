import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  void changePage(int index) => emit(index);

  void nextPage(int total) {
    if (state < total - 1) emit(state + 1);
  }

  bool isLastPage(int total) => state == total - 1;
}
