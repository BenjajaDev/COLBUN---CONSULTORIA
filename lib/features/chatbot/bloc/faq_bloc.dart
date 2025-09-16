import 'package:flutter_bloc/flutter_bloc.dart';

part 'faq_event.dart';
part 'faq_state.dart';

class FaqBloc extends Bloc<FaqEvent, FaqState> {
  FaqBloc() : super(const FaqState(showFaqs: false)) {
    on<ToggleFaqsEvent>((event, emit) {
      emit(state.copyWith(showFaqs: !state.showFaqs));
    });
  }
}