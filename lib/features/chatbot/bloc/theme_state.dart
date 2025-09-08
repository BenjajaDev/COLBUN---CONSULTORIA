part of 'theme_bloc.dart';

class ThemeState {
  final bool isDarkMode;

  const ThemeState({required this.isDarkMode});

  ThemeState copyWith({bool? isDarkMode}) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeState && other.isDarkMode == isDarkMode;
  }

  @override
  int get hashCode => isDarkMode.hashCode;
}