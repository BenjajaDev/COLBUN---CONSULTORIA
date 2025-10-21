part of 'theme_bloc.dart';

enum FontSize {
  small,
  medium,
  large,
}

class ThemeState {
  final bool isDarkMode;
  final FontSize fontSize;

  const ThemeState({
    required this.isDarkMode,
    this.fontSize = FontSize.medium,
  });

  ThemeState copyWith({
    bool? isDarkMode,
    FontSize? fontSize,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  // Obtener multiplicador de tamaño de fuente
  double get fontSizeMultiplier {
    switch (fontSize) {
      case FontSize.small:
        return 0.85;
      case FontSize.medium:
        return 1.0;
      case FontSize.large:
        return 1.15;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeState && 
           other.isDarkMode == isDarkMode &&
           other.fontSize == fontSize;
  }

  @override
  int get hashCode => isDarkMode.hashCode ^ fontSize.hashCode;
}