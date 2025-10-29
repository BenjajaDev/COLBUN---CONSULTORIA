import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(isDarkMode: false)) {
    on<ToggleThemeEvent>(_onToggleTheme);
    on<ChangeFontSizeEvent>(_onChangeFontSize);
  }

  void _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void _onChangeFontSize(ChangeFontSizeEvent event, Emitter<ThemeState> emit) {
    emit(state.copyWith(fontSize: event.fontSize));
  }
}