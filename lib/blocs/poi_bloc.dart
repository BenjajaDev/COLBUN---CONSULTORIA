import 'package:consultoria_chat_bot/events/poi_event.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PoiBloc extends Bloc<PoiEvent, PoiState> {
  PoiBloc() : super(POI()) ;
}

