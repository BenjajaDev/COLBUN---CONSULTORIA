import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/screens/emergency_screen.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:consultoria_chat_bot/screens/favorites_screen.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import '../widget/filter_modal.dart';
import 'available_pois_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:consultoria_chat_bot/theme.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/services/analytics_service.dart';

const String kMapTilerApiKey = 'HiDxah3SS2m47uoakaIA';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
  );
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  final DraggableScrollableController _draggableSheetController =
      DraggableScrollableController();
  String _lastSearchText = '';
  int? selectedRouteIndex;
  // Inicial definido en 0.28 para que el modo colapsado coincida con el nuevo mínimo sin generar "BOTTOM OVERFLOWED".
  final double _initialSheetChildSize = 0.28;
  // Seguimiento del tamaño objetivo para animar el sheet según la visibilidad del teclado y evitar overflow.
  double _currentSheetTargetSize = 0.28;
  double _dragScrollSheetExtent = 0;
  double _widgetHeight = 0;
  double _fabPosition = 0;
  Type? _lastStateType;
  bool _centeredOnNavStart = false; // Center map once when navigation starts

  bool _isOffline = false;
  Timer? _netTimer;
  double _currentZoom = 15.0;
  bool _showPoiLabels = true; // toggle POI name visibility based on zoom

  final double _fabPositionPadding = 10;

  @override
  void initState() {
    BlocProvider.of<MapBloc>(context).add(LoadRoute());
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _fabPosition =
            _initialSheetChildSize * MediaQuery.of(context).size.height;
      });
    });
    _startNetworkMonitoring();
  }

  void _startNetworkMonitoring() {
    _checkConnectivity();
    _netTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  // === Helper reutilizable: MISMO estilo que el toast/snackbar de "Añadido a favoritos" ===
  void _showStyledSnackBar(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? theme.colorScheme.surface
            : Colors.white, // igual que favs
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 3),
        action: action,
      ),
    );
  }
  // === Fin helper ===

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Material(
      color:
          backgroundColor ??
          (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: iconColor ?? theme.colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (mounted && _isOffline == online) {
        setState(() => _isOffline = !online);
      } else if (mounted && _isOffline != !online) {
        setState(() => _isOffline = !online);
      }
    } catch (_) {
      if (mounted && !_isOffline) setState(() => _isOffline = true);
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    searchController.dispose();
    _draggableSheetController.dispose();
    _netTimer?.cancel();
    super.dispose();
  }

  void _openFilterSheet(MapLoaded state) {
    FocusScope.of(context).unfocus();

    double computedMaxDistance = state.allRoutes.fold<double>(
      0,
      (prev, route) => route.distanceKm != null && route.distanceKm! > prev
          ? route.distanceKm!
          : prev,
    );

    if (computedMaxDistance <= 0) computedMaxDistance = 100;
    if (computedMaxDistance < 10) computedMaxDistance = 10;
    if (computedMaxDistance > 200) computedMaxDistance = 200;

    final sliderDivisions = computedMaxDistance.round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Use themed surface color so the sheet adapts to dark/light mode
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FilterModal(
          categories: state.categories,
          activities: state.activities,
          computedMaxDistance: computedMaxDistance,
          sliderDivisions: sliderDivisions,
          initialCategory: state.selectedCategory,
          initialActivity: state.selectedActivity,
          initialDistance: state.selectedDistanceKm ?? 0,
          initialSeason: state.selectedSeason,
          primaryColor: Theme.of(context).colorScheme.primary,
          searchController: searchController,
          onFiltersApplied: () {
            // Mantengo tu lógica: limpiar selección de ruta si existe
            if (selectedRouteIndex != null && mounted) {
              setState(() {
                selectedRouteIndex = null;
              });
            }
            // === Mostrar el "toast" con EL MISMO ESTILO/UBICACIÓN que Favoritos ===
            _showStyledSnackBar(
              // uso el context del sheet: el ScaffoldMessenger resuelve al de la página
              context,
              message: 'Filtros aplicados',
              // sin acción, como pediste (solo el mensaje)
              // si luego quieres una acción tipo "Quitar filtros", se agrega aquí.
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<MapBloc, MapState>(
          listener: (context, state) {
            if (state is MapError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          child: BlocBuilder<MapBloc, MapState>(
            builder: (context, state) {
              // Recalculate FAB position on state type change and reset one-time centering on nav start
              final currentType = state.runtimeType;
              if (_lastStateType != currentType) {
                _lastStateType = currentType;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final height = MediaQuery.of(context).size.height;
                  setState(() {
                    _widgetHeight = height;
                    _dragScrollSheetExtent = _initialSheetChildSize;
                    _fabPosition = _initialSheetChildSize * height;
                    // Reset one-time centering when entering navigation
                    if (state is MapNavigating) {
                      _centeredOnNavStart = false;
                    }
                  });
                });
              }

              if (state is MapLoaded) {
                if (searchController.text != state.query) {
                  searchController.value = TextEditingValue(
                    text: state.query,
                    selection: TextSelection.collapsed(
                      offset: state.query.length,
                    ),
                  );
                  // Keep track of last programmatic text to help detect
                  // keyboard auto-period (double-space -> ". ") behavior.
                  _lastSearchText = state.query;
                }

                if (selectedRouteIndex != null &&
                    (selectedRouteIndex! < 0 ||
                        selectedRouteIndex! >= state.filteredRoutes.length)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        selectedRouteIndex = null;
                      });
                    }
                  });
                }
              }
              if (state is MapNavigating) {
                final route = state.routePoints;
                if (route.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Keep rotating to current bearing during navigation

                    // Center only once when navigation starts
                    if (!_centeredOnNavStart) {
                      final userPos = state.userLocation ?? state.start;
                      mapController.move(userPos, 16.5);
                      _centeredOnNavStart = true;
                    }
                  });
                }
              }
              final mediaQuery = MediaQuery.of(context);
              final double keyboardInset = mediaQuery.viewInsets.bottom;
              final bool isKeyboardVisible = keyboardInset > 0;
              // Ajuste dinámico de los límites del sheet para evitar "BOTTOM OVERFLOWED" al mostrarse u ocultarse el teclado.
              const double collapsedMinSize = 0.28;
              const double collapsedMaxSize = 0.72;
              const double expandedMinSize = 0.9;
              const double expandedMaxSize = 0.96;
              const double collapsedInitialSize = collapsedMinSize;
              const double expandedInitialSize = 0.92;
              final double targetMinSize = isKeyboardVisible
                  ? expandedMinSize
                  : collapsedMinSize;
              final double targetMaxSize = isKeyboardVisible
                  ? expandedMaxSize
                  : collapsedMaxSize;
              final double targetInitialSize = isKeyboardVisible
                  ? expandedInitialSize
                  : collapsedInitialSize;

              if ((targetInitialSize - _currentSheetTargetSize).abs() > 0.001) {
                final double viewportHeight = mediaQuery.size.height;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }
                  if (_draggableSheetController.isAttached) {
                    _draggableSheetController.animateTo(
                      targetInitialSize.clamp(targetMinSize, targetMaxSize),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                    );
                  }
                  setState(() {
                    _currentSheetTargetSize = targetInitialSize;
                    _dragScrollSheetExtent = targetInitialSize;
                    _widgetHeight = viewportHeight;
                    _fabPosition = targetInitialSize * viewportHeight;
                  });
                });
              }
              // Choose tile style depending on current theme
              final bool isDark =
                  Theme.of(context).brightness == Brightness.dark;
              final String tilesUrl = isDark
                  ? 'https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key=$kMapTilerApiKey'
                  : 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$kMapTilerApiKey';
              return Stack(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateX(state is MapNavigating ? 0.6 : 0.0),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(-35.6960057, -71.4060907),
                        initialZoom: 15,
                        onMapEvent: (event) {
                          final z = event.camera.zoom;
                          if (z != _currentZoom) {
                            final show = z >= 14.0;
                            if (show != _showPoiLabels) {
                              setState(() {
                                _showPoiLabels = show;
                              });
                            }
                            _currentZoom = z;
                          }
                        },
                        // Testing helper: tap the map to update the user's position
                        onTap: (tapPosition, point) {
                          try {
                            // Move the visible map to the tapped point
                            // Use a fixed zoom when centering on tap for testing
                            mapController.move(point, 15.0);
                            // Dispatch an UpdateUserLocation for quick testing (not altering bloc structure)
                            context.read<MapBloc>().add(
                              UpdateUserLocation(point),
                            );
                          } catch (e) {
                            // ignore errors in testing hook
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          key: ValueKey(tilesUrl),
                          tileProvider: _tileProvider,
                          urlTemplate: tilesUrl,
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (state is MapLoaded)
                              ...state.filteredPois.map(
                                (poi) => Marker(
                                  point: LatLng(poi.latitud, poi.longitud),
                                  width: 120,
                                  height: 84,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Analytics: abrir POI desde marcador del mapa
                                      AnalyticsService.logAbrirPOI(poi.id, poi.nombre);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PoiScreen(poi),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 2),
                                        if (_showPoiLabels)
                                          Text(
                                            poi.nombre,
                                            textAlign: TextAlign.center,
                                            softWrap: true,
                                            maxLines: 2,
                                            overflow: TextOverflow.fade,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (state is MapLoaded)
                              if (state.userLocation != null)
                                Marker(
                                  point: state.userLocation!,
                                  child: Transform.rotate(
                                    angle: state.heading * (3.1415926535 / 180),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4D67AE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.navigation, // Flecha tipo brujula
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            if (state is MapNavigating)
                              if (state.userLocation != null)
                                Marker(
                                  point: state.userLocation!,
                                  child: Builder(
                                    builder: (context) {
                                      // Use a safe bearing value; fall back to 0.0 if null
                                      final double bearingDeg =
                                          state.bearing ?? 0.0;
                                      final double angleRad =
                                          bearingDeg * (math.pi / 180);
                                      return Transform.rotate(
                                        angle: angleRad,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4D67AE),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.navigation,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          ],
                        ),
                        if (state is MapLoaded)
                          PolylineLayer(
                            polylines: state.filteredRoutes.map((route) {
                              final List<LatLng> pts =
                                  (route.geometry.isNotEmpty)
                                  ? route.geometry
                                  : [
                                      LatLng(
                                        route.initialLatitude,
                                        route.initialLongitude,
                                      ),
                                      LatLng(
                                        route.finalLatitude,
                                        route.finalLongitude,
                                      ),
                                    ];
                              return Polyline(
                                points: pts,
                                strokeWidth: 4.0,
                                color: Colors.red,
                              );
                            }).toList(),
                          ),
                        if (state is MapNavigating)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: state.routePoints,
                                strokeWidth: 5.0,
                                color: Colors.blueAccent,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: _fabPosition + _fabPositionPadding,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'centerFab',
                      backgroundColor: const Color(0xFF4D67AE),
                      onPressed: () {
                        // Use the user's location when available, otherwise fall back to a default center
                        mapController.move(
                          state is MapLoaded && state.userLocation != null
                              ? state.userLocation!
                              : const LatLng(-35.6960057, -71.4060907),
                          15,
                        ); // Centrar
                      },
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                  // FAB de emergencia, ubicado encima del botón de centrar ubicación
                  Positioned(
                    bottom: _fabPosition + _fabPositionPadding + 72,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'emergencyFab',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmergencyScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.call),
                    ),
                  ),
                  if (state is MapLoaded)
                    if (_isOffline)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 36,
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Icon(Icons.wifi_off, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.modo_sin_conexion,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (state is MapLoaded)
                    NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        setState(() {
                          _widgetHeight = MediaQuery.of(context).size.height;
                          _dragScrollSheetExtent = notification.extent;
                          _fabPosition = _dragScrollSheetExtent * _widgetHeight;
                        });
                        return true;
                      },
                      child: DraggableScrollableSheet(
                        controller: _draggableSheetController,
                        initialChildSize: targetInitialSize,
                        minChildSize: targetMinSize,
                        maxChildSize: targetMaxSize,
                        snap: true,
                        builder: (context, scrollController) {
                          return AvailablePoisRoutesSheet(
                            state: state,
                            selectedRouteIndex: selectedRouteIndex,
                            onRouteSelected: (index) {
                              setState(() {
                                selectedRouteIndex = index;
                              });
                            },
                            onClearSelectedRoute: () {
                              setState(() {
                                selectedRouteIndex = null;
                              });
                            },
                            onMoveMap: (LatLng center, {double? zoom}) {
                              mapController.move(center, zoom ?? 14);
                            },
                            setSelectedRouteIndex: (int? index) {
                              setState(() {
                                selectedRouteIndex = index;
                              });
                            },
                            primaryColorOpacity: 0.12,
                            primaryColor: Theme.of(context).colorScheme.primary,
                            mapController: mapController,
                            scrollController: scrollController,
                            draggableController: _draggableSheetController,
                            minChildSize: targetMinSize,
                            maxChildSize: targetMaxSize,
                          );
                        },
                      ),
                    ),
                  if (state is MapNavigating)
                    NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        setState(() {
                          _widgetHeight = MediaQuery.of(context).size.height;
                          _dragScrollSheetExtent = notification.extent;
                          _fabPosition = _dragScrollSheetExtent * _widgetHeight;
                        });
                        return true;
                      },
                      child: DraggableScrollableSheet(
                        controller: _draggableSheetController,
                        initialChildSize: targetInitialSize,
                        minChildSize: targetMinSize,
                        maxChildSize: targetMaxSize,
                        snap: true,
                        builder: (context, scrollController) {
                          // compute distance/time/eta from instructions
                          final List<Map<String, dynamic>> instructions =
                              state.instructions;
                          double distanceMeters = 0.0;
                          double durationSeconds = 0.0;
                          for (final ins in instructions) {
                            distanceMeters +=
                                (ins['distance'] as num?)?.toDouble() ?? 0.0;
                            durationSeconds +=
                                (ins['duration'] as num?)?.toDouble() ?? 0.0;
                          }

                          String distanceText;
                          if (distanceMeters < 1000) {
                            distanceText = '${distanceMeters.round()} m';
                          } else {
                            distanceText =
                                '${(distanceMeters / 1000).toStringAsFixed(1)} km';
                          }

                          String durationText;
                          final dur = Duration(
                            seconds: durationSeconds.round(),
                          );
                          if (dur.inHours > 0) {
                            durationText =
                                '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
                          } else {
                            durationText = '${dur.inMinutes} min';
                          }

                          final eta = DateTime.now().add(dur);
                          final etaText = TimeOfDay.fromDateTime(
                            eta,
                          ).format(context);

                          return AnimatedPadding(
                            // Padding animado que reserva el espacio del teclado para evitar "BOTTOM OVERFLOWED".
                            padding: EdgeInsets.only(
                              bottom: mediaQuery.viewInsets.bottom,
                            ),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          width: 50,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.ruta_en_curso,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.map,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Toggle tema claro/oscuro
                                                    IconButton(
                                                      style: IconButton.styleFrom(
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .surface,
                                                        foregroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                        shape:
                                                            const CircleBorder(),
                                                      ),
                                                      onPressed: () {
                                                        context
                                                            .read<
                                                              ThemeProvider
                                                            >()
                                                            .toggleTheme();
                                                      },
                                                      icon: Icon(
                                                        context
                                                                    .watch<
                                                                      ThemeProvider
                                                                    >()
                                                                    .themeMode ==
                                                                ThemeMode.dark
                                                            ? Icons.dark_mode
                                                            : Icons.light_mode,
                                                      ),
                                                    ),
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.distancia_fmt(
                                                        distanceText,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.tiempo_aprox_fmt(
                                                        durationText,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.schedule,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.llegada_aprox_fmt(
                                                        etaText,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              foregroundColor: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                            onPressed: () {
                                              // cancel navigation
                                              context.read<MapBloc>().add(
                                                CancelNavigation(),
                                              );
                                            },
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.cancelar,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (state is MapLoaded)
                    Positioned(
                      top: _isOffline ? 60 : 16,
                      left: 16,
                      right: 16,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          key: ValueKey<bool>(
                            Theme.of(context).brightness == Brightness.dark,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.surface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  cursorColor: const Color(0xFF4D67AE),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  onChanged: (value) {
                                    String toSend = value;
                                    if (value.endsWith('. ') &&
                                        _lastSearchText.endsWith(' ')) {
                                      toSend =
                                          '${value.substring(0, value.length - 2)}  ';
                                      searchController.value = TextEditingValue(
                                        text: toSend,
                                        selection: TextSelection.collapsed(
                                          offset: toSend.length,
                                        ),
                                      );
                                    }
                                    _lastSearchText = toSend;
                                    context.read<MapBloc>().add(
                                      SearchQueryUpdated(toSend),
                                    );
                                  },
                                  onSubmitted: (term) async {
                                    final s = context.read<MapBloc>().state;
                                    int total = 0;
                                    if (s is MapLoaded) {
                                      total = (s.filteredRoutes.length) + (s.filteredPois.length);
                                    }
                                    await AnalyticsService.logRealizarBusqueda(term, total);
                                  },
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF4D67AE),
                                    ),
                                    hintText: 'Buscar rutas o lugares...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildQuickActionButton(
                                icon: Icons.tune_rounded,
                                onTap: () => _openFilterSheet(state),
                                iconColor: const Color(0xFF4D67AE),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickActionButton(
                                icon:
                                    context.watch<ThemeProvider>().themeMode ==
                                        ThemeMode.dark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                onTap: () {
                                  context.read<ThemeProvider>().toggleTheme();
                                },
                                iconColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : const Color(0xFF4D67AE),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickActionButton(
                                icon: Icons.favorite_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FavoritesScreen(),
                                    ),
                                  );
                                },
                                iconColor: const Color(0xFFE63946),
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest
                                    : const Color(
                                        0xFFE63946,
                                      ).withValues(alpha: 0.12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (state is MapNavigating) ...[
                    Positioned(
                      top: 20,
                      left: 16,
                      right: 16,
                      child: _buildCurrentInstructionBanner(
                        // ignore: unnecessary_cast
                        (state as MapNavigating).instructions,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentInstructionBanner(
    List<Map<String, dynamic>> instructions,
  ) {
    if (instructions.isEmpty) return const SizedBox.shrink();

    final current = instructions.first;
    final instruction = current['instruction'] ?? '';
    final distance = current['distance'] ?? 0.0;

    String distanceText;
    if (distance < 1000) {
      distanceText = '${distance.toStringAsFixed(0)} m';
    } else {
      distanceText = '${(distance / 1000).toStringAsFixed(1)} km';
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.navigation,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distanceText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
