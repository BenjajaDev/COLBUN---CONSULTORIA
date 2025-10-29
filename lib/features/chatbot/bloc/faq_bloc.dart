import 'package:flutter_bloc/flutter_bloc.dart';

part 'faq_event.dart';
part 'faq_state.dart';

class FaqBloc extends Bloc<FaqEvent, FaqState> {
  FaqBloc() : super(const FaqState(showFaqs: false)) {
    on<ToggleFaqsEvent>(_onToggleFaqs);
  }

  void _onToggleFaqs(ToggleFaqsEvent event, Emitter<FaqState> emit) {
    if (event.newFaqs != null) {
      emit(state.copyWith(
        showFaqs: true,
        currentFaqs: event.newFaqs!
      ));
    } else {
      emit(state.copyWith(
        showFaqs: !state.showFaqs,
        currentFaqs: state.showFaqs ? [] : state.currentFaqs
      ));
    }
  }
}