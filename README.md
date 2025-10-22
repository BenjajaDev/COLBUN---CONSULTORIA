# COLBUN — Consultoría (Flutter)

Aplicación Flutter para explorar rutas y puntos de interés (POIs) con navegación paso a paso, reencaminamiento en vivo y localización. Usa Flutter BLoC para el estado, flutter_map para el mapa, OpenRouteService para el ruteo y Firebase Cloud Firestore para el contenido.

## Funcionalidades

- Explorar rutas y POIs
	- Búsqueda por nombre, filtro por categoría/temporada/distancia
	- Marcadores dinámicos según los filtros
- Navegación giro a giro
	- Distancia restante, duración y hora estimada de llegada (ETA) en vivo (una actualización por tick)
	- Progreso proporcional del paso: la distancia/duración restante del paso actual disminuye mientras avanzas
	- Consumo de instrucciones al acercarse a su punto representativo
	- Reencaminamiento cuando te desvías de la ruta (con enfriamiento)
	- Inclinación 3D opcional durante la navegación
- UI/UX pulida
	- DraggableScrollableSheet para instrucciones con scroll correcto
	- Cancelar navegación vuelve al estado de exploración previo
	- El FAB (botón flotante) ajusta su posición al cambiar de estado
- Datos y localización
	- Contenido desde Firestore (whereIn con particiones, validaciones de entrada vacía)
	- Localización con gen-l10n (ARB ES/EN/PT)
- Comodidades para desarrollo
	- Hook de pruebas: tocar el mapa simula la posición del usuario (solo dev)

## Stack técnico

- Flutter 3.24+ (Dart >= 3.9)
- State management: flutter_bloc
- Render de mapa: flutter_map + latlong2
- Sensores: geolocator (GPS), flutter_compass (rumbo)
- Ruteo: OpenRouteService (direcciones geojson)
- Backend: Firebase Cloud Firestore

## Estructura del proyecto (alto nivel)

- `lib/blocs/` — BLoCs, eventos y estados (ej.: `map_bloc.dart`)
- `lib/screens/` — Pantallas de UI (ej.: `map_page.dart`, pantallas de POI)
- `lib/services/` — Ayudantes para Firebase/Firestore
- `lib/model/` — Modelos de datos
- `lib/l10n/` — Archivos ARB de localización

Archivos clave de ejemplo:

- `lib/blocs/map_bloc.dart` — Lógica de navegación: recorte de polilínea, progreso de instrucciones, reencaminamiento y documentación en español.
- `lib/screens/map_page.dart` — UI principal del mapa: marcadores, polilíneas, hoja arrastrable, tap para simular ubicación.

## Requisitos previos

- Flutter SDK 3.24+ y Dart 3.9+ (ver `environment.sdk` en `pubspec.yaml`)
- Android Studio o Xcode (para emuladores o dispositivos)
- Proyecto de Firebase (Cloud Firestore habilitado)
- Clave de API de OpenRouteService

## Configuración

### Firebase

- Android: se requiere `android/app/google-services.json` (ya incluido aquí).
- iOS: agrega tu `GoogleService-Info.plist` en `ios/Runner/` y asegúrate de incluirlo en la configuración del proyecto en Xcode.
- Web/Escritorio: configura según corresponda si vas a apuntar a esas plataformas.

### OpenRouteService (ruteo)

La clave de la API se lee desde una variable de entorno de compilación usando `--dart-define` y `String.fromEnvironment('ORS_API_KEY')` (ver `lib/blocs/map_bloc.dart`).

- Define la clave al ejecutar o compilar con: `--dart-define=ORS_API_KEY=TU_CLAVE`.
- Si no se define la clave, la app mostrará un error informando que falta configurar la API Key.

### API de mapas (MapTiler)

La capa de mapas usa MapTiler (TileLayer con URL `api.maptiler.com`). Requiere una API Key propia.

- La clave se lee mediante `--dart-define=MAPTILER_API_KEY=...` y `String.fromEnvironment('MAPTILER_API_KEY')` (ver `lib/screens/map_page.dart`).
- Crea tu API Key gratis en https://www.maptiler.com/ y respeta sus límites de uso y atribución.
- Si no configuras la clave, es probable que el mapa no cargue (errores 401/403).

### Permisos de ubicación

Asegúrate de configurar los permisos por plataforma:

- Android: declara los permisos de ubicación en `AndroidManifest.xml` y verifica que Google Play Services esté disponible en el dispositivo/emulador.
- iOS: agrega `NSLocationWhenInUseUsageDescription` (y/o `NSLocationAlwaysAndWhenInUseUsageDescription`) en `Info.plist`.

## Ejecución de la app

1) Instalar dependencias

- Ejecuta la resolución de paquetes de Flutter. Este proyecto usa `flutter generate: true` para generar artefactos de localización automáticamente.

2) Configurar Firebase y OpenRouteService

- Coloca los archivos de Firebase como se indica arriba.
- Pasa tu clave de OpenRouteService con `--dart-define=ORS_API_KEY=...` al ejecutar/compilar.

3) Lanzar

- Inicia en un dispositivo conectado o emulador (`flutter run`).

Consejo: permite los permisos de ubicación cuando se soliciten. Si pruebas en interiores o sin GPS, usa el hook de pruebas (tocar para fijar ubicación) descrito abajo.

### Ejemplos de comandos (Windows PowerShell)

Ejecutar en dispositivo/emulador Android (debug):

```
flutter run --dart-define=ORS_API_KEY='TU_CLAVE_ORS' --dart-define=MAPTILER_API_KEY='TU_CLAVE_MAPTILER'
```

Compilar APK (release) para Android:

```
flutter build apk --release --dart-define=ORS_API_KEY='TU_CLAVE_ORS' --dart-define=MAPTILER_API_KEY='TU_CLAVE_MAPTILER'
```

Compilar App Bundle (AAB) para Play Store:

```
flutter build appbundle --release --dart-define=ORS_API_KEY='TU_CLAVE_ORS' --dart-define=MAPTILER_API_KEY='TU_CLAVE_MAPTILER'
```

Ejecutar en Chrome (web):

```
flutter run -d chrome --dart-define=ORS_API_KEY='TU_CLAVE_ORS' --dart-define=MAPTILER_API_KEY='TU_CLAVE_MAPTILER'
```

Ejecutar app de escritorio en Windows:

```
flutter run -d windows --dart-define=ORS_API_KEY='TU_CLAVE_ORS' --dart-define=MAPTILER_API_KEY='TU_CLAVE_MAPTILER'
```

Notas:

- En PowerShell, las comillas simples evitan la expansión de variables; úsalas si tus claves contienen caracteres especiales.
- No compartas la clave en repos públicos ni la hardcodes en el código; usa siempre `--dart-define` u otros mecanismos seguros.

## Localización (gen-l10n)

- Los ARB viven en `lib/l10n/` y se compilan con gen-l10n de Flutter (habilitado en `pubspec.yaml`).
- Para agregar/editar textos, actualiza los ARB correspondientes (p. ej., `app_es.arb`, `app_en.arb`, `app_pt.arb`) y vuelve a compilar.
- Las localizaciones generadas están disponibles vía `AppLocalizations.of(context)`.

## Detalles de navegación

- `MapBloc` gestiona las transiciones del estado de navegación:
	- `RequestNavigation` calcula una ruta desde el usuario al destino seleccionado.
	- `UpdateUserLocation` actualiza el avance en cada tick:
		- Recorta la polilínea cerca del siguiente vértice
		- Reduce proporcionalmente la distancia/duración restante del paso actual
		- Consume el paso al estar cerca de su `point` representativo
		- Recalcula distancia restante, duración y ETA en `navigationInfo`
	- `CancelNavigation` restaura el último `MapLoaded` y limpia los rastreadores internos.
- La detección de desvío usa distancia a segmento (umbral ≈ 30 m) con 8 s de enfriamiento para reencaminar. Puedes ajustarlo en `map_bloc.dart`.

### Estructura de `navigationInfo`

En navegación, el estado incluye un mapa `navigationInfo` con:

- `remainingDistance` (metros)
- `remainingDuration` (segundos)
- `eta` (cadena ISO8601)
- `originalDistance` (metros, ruta completa) — opcional
- `originalDuration` (segundos, suma de pasos) — opcional

## Notas para desarrollo

- Tap para fijar ubicación (pruebas):
	- En `lib/screens/map_page.dart`, tocar el mapa actualiza la posición del usuario al punto tocado. Útil para desarrollo/pruebas. Considera protegerlo con `kDebugMode` o un flag para producción.
- Scroll de la hoja de instrucciones:
	- La hoja cablea el `scrollController` interno para asegurar un comportamiento correcto entre arrastre y scroll.
- Posición del FAB:
	- El botón flotante se reposiciona cuando cambia el tipo de estado (entrar/salir de navegación) para mantener la coherencia.

## Resolución de problemas

- La ubicación no se actualiza:
	- Verifica permisos de plataforma y que los servicios de ubicación estén activos.
	- En emuladores, fija una ubicación simulada.
- El reencaminamiento es muy sensible o muy lento:
	- Ajusta el umbral de desvío y el enfriamiento en `MapBloc` (`_checkDeviationFromRoute` y `_shouldRecalculate`).
- Las instrucciones no coinciden con los pasos esperados:
	- Asegúrate de que `way_points` produzca puntos representativos válidos al parsear. El código es tolerante, pero se apoya en índices provistos por la API para mejores resultados.

## Scripts y calidad

- Lints mediante `analysis_options.yaml` con `flutter_lints`.
- La localización se genera automáticamente al compilar (`flutter generate: true`).

## Licencia

Este repositorio no incluye un archivo de licencia. Si planeas abrir el código, agrega una LICENSE adecuada. De lo contrario, trátalo como de uso interno/proprietario.
