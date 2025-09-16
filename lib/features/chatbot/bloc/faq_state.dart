part of 'faq_bloc.dart';

class FaqState {
  final bool showFaqs;

  const FaqState({required this.showFaqs});

  FaqState copyWith({bool? showFaqs}) {
    return FaqState(showFaqs: showFaqs ?? this.showFaqs);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaqState && other.showFaqs == showFaqs;
  }

  @override
  int get hashCode => showFaqs.hashCode;
}