import 'package:consultoria_chat_bot/events/poi_event.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Bloc que maneja eventos y estados relacionados con los POIs (Puntos de Interés).
class PoiBloc extends Bloc<PoiEvent, PoiState> {
  // Inicializa el estado con PoiInitial y registra handler para LoadPoi.
  PoiBloc() : super(PoiInitial()) {
    on<LoadPoi>(_onLoadPoi);
  }

  // Handler asincrónico para cargar los POIs cuando se recibe el evento LoadPoi.
  void _onLoadPoi(LoadPoi event, Emitter<PoiState> emit) async {
    try {
      // Emite estado de carga mientras se preparan los datos.
      emit(PoiLoading());

      // Luego emite el estado de datos cargados con éxito (aquí falta lógica de carga real).
      emit(PoiLoaded());
    } catch (e) {
      // En caso de error emite estado de error con mensaje.
      emit(PoiError("Error al cargar los datos"));
    }
  }
}
