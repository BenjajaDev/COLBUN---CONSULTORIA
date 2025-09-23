import 'package:consultoria_chat_bot/events/poi_event.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PoiBloc extends Bloc<PoiEvent, PoiState> {
  PoiBloc() : super(PoiInitial()) {
    on<LoadPoi>(_onLoadPoi);
  }
  void _onLoadPoi(LoadPoi event, Emitter<PoiState> emit) async {
    try {
      emit(PoiLoading());
      
      emit(PoiLoaded());
    } catch (e) {
      emit(PoiError("Error al cargar los datos"));
    }
  }


}

