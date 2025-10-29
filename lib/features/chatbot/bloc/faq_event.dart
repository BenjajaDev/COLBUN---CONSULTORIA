part of 'faq_bloc.dart';

abstract class FaqEvent {}

class ToggleFaqsEvent extends FaqEvent {
  final List<String>? newFaqs;

  ToggleFaqsEvent({this.newFaqs});
}