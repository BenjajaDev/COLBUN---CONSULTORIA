part of 'faq_bloc.dart';

class FaqState {
  final bool showFaqs;
  final List<String> currentFaqs;

  const FaqState({
    required this.showFaqs, 
    this.currentFaqs = const []
  });

  FaqState copyWith({
    bool? showFaqs, 
    List<String>? currentFaqs
  }) {
    return FaqState(
      showFaqs: showFaqs ?? this.showFaqs,
      currentFaqs: currentFaqs ?? this.currentFaqs
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaqState && other.showFaqs == showFaqs;
  }

  @override
  int get hashCode => showFaqs.hashCode;
}