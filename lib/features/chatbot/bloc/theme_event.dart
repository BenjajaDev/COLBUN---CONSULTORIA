part of 'theme_bloc.dart';

abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class ChangeFontSizeEvent extends ThemeEvent {
  final FontSize fontSize;
  
  ChangeFontSizeEvent(this.fontSize);
}