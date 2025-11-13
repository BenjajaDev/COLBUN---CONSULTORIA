import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:consultoria_chat_bot/events/map_event.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/screens/poi_screen.dart';
import 'package:consultoria_chat_bot/services/local_storage.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:consultoria_chat_bot/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Hoja inferior que muestra las rutas disponibles y sus POIs.
/// Mantiene intacta la lógica original y refuerza únicamente la experiencia visual.
class AvailablePoisRoutesSheet extends StatelessWidget {
  /// Estado actual del [MapBloc] (habitualmente [MapLoaded]).
  final dynamic state;

  /// Índice de la ruta actualmente seleccionada.
  final int? selectedRouteIndex;

  /// Se ejecuta al tocar una ruta dentro del listado.
  final void Function(int) onRouteSelected;

  /// Limpia la ruta seleccionada.
  final VoidCallback onClearSelectedRoute;

  /// Desplaza el mapa a un centro y zoom determinados.
  final void Function(LatLng, {double? zoom}) onMoveMap;

  /// Persiste el índice de la ruta seleccionada en el padre.
  final void Function(int?) setSelectedRouteIndex;

  /// Opacidad aplicada a los acentos del color primario.
  final double primaryColorOpacity;

  /// Color primario utilizado para mantener la coherencia visual del rediseño.
  final Color primaryColor;

  /// Controlador de mapa provisto por el padre (conservado para compatibilidad).
  final MapController mapController;

  /// Controlador de scroll compartido con la hoja deslizable.
  final ScrollController scrollController;

  /// Controlador que permite al padre administrar la posición vertical del sheet.
  final DraggableScrollableController draggableController;

  /// Extensión mínima permitida para la hoja.
  final double minChildSize;

  /// Extensión máxima permitida para la hoja.
  final double maxChildSize;

  static const ScrollPhysics _sheetScrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
  static const EdgeInsets _sheetContentPadding = EdgeInsets.fromLTRB(
    16,
    8,
    16,
    24,
  );

  const AvailablePoisRoutesSheet({
    super.key,
    required this.state,
    required this.selectedRouteIndex,
    required this.onRouteSelected,
    required this.onClearSelectedRoute,
    required this.onMoveMap,
    required this.setSelectedRouteIndex,
    required this.primaryColorOpacity,
    required this.primaryColor,
    required this.mapController,
    required this.scrollController,
    required this.draggableController,
    required this.minChildSize,
    required this.maxChildSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // ViewInsets detecta el teclado y evita "BOTTOM OVERFLOWED" ajustando el padding inferior.
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    final bool isLoaded = state is MapLoaded;
    final String query = isLoaded ? (state as MapLoaded).query : '';
    final bool hasSearch = query.trim().isNotEmpty;
    final filteredRoutes = isLoaded
        ? (state as MapLoaded).filteredRoutes
        : <dynamic>[];
    final filteredPois = isLoaded
        ? (state as MapLoaded).filteredPois
        : <dynamic>[];
    final dynamic selectedRoute =
        (selectedRouteIndex != null &&
            selectedRouteIndex! >= 0 &&
            selectedRouteIndex! < filteredRoutes.length)
        ? filteredRoutes[selectedRouteIndex!]
        : null;

    final double resolvedOpacity =
        (primaryColorOpacity <= 0 ? 0.12 : primaryColorOpacity)
            .clamp(0.07, 0.25)
            .toDouble();

    /// Lista con padding uniforme y física consistente para cada vista del sheet.
    ListView buildSheetListView({
      required Key key,
      required List<Widget> children,
    }) {
      return ListView(
        key: key,
        controller: scrollController,
        physics: _sheetScrollPhysics,
        padding: _sheetContentPadding,
        children: children,
      );
    }

    /// Chip redondeado que refuerza datos contextuales (distancia, resultados, etc.).
    Widget buildInfoChip({required IconData icon, required String label}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: resolvedOpacity),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    /// Estado vacío reutilizable para rutas o POIs sin coincidencias.
    Widget buildEmptyState({
      required IconData icon,
      required String title,
      required String description,
    }) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: resolvedOpacity),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Poppins',
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    /// Título de sección que mantiene la jerarquía visual interna del sheet.
    Widget buildSectionTitle(String title) {
      return Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      );
    }

    /// Tarjeta de ruta con animaciones suaves y acentos acordes al estado seleccionado.
    Widget buildRouteCard({required dynamic route, required int index}) {
      final bool isSelected = selectedRouteIndex == index;
      final int poiCount = (route.pois is List)
          ? (route.pois as List).length
          : 0;
      final double? distanceKm = route.distanceKm is num
          ? (route.distanceKm as num?)?.toDouble()
          : null;
      final String distanceLabel = (distanceKm != null && distanceKm > 0)
          ? (distanceKm >= 10
                ? distanceKm.toStringAsFixed(0)
                : distanceKm.toStringAsFixed(1))
          : '--';
      final String poiLabel = poiCount == 1 ? '1 POI' : '$poiCount POIs';

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: resolvedOpacity)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.14 : 0.08),
              blurRadius: isSelected ? 20 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            // Enfoca la cámara para mostrar toda la ruta (geometry o fallback a inicio/fin)
            final List<LatLng> pts =
                (route.geometry != null && route.geometry.isNotEmpty)
                ? route.geometry
                : <LatLng>[
                    LatLng(route.initialLatitude, route.initialLongitude),
                    LatLng(route.finalLatitude, route.finalLongitude),
                  ];
            if (pts.isNotEmpty) {
              final bounds = LatLngBounds.fromPoints(pts);
              mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(48),
                ),
              );
            }
            // Analytics: abrir ruta
            await AnalyticsService.logAbrirRuta(route.id, route.name);
            setSelectedRouteIndex(index);

            if (selectedRouteIndex != index){
              await LocalStorage.setLastRouteName(route.name);
              await LocalStorage.setLastRouteWithPois(route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.ruta} ${route.name}',
                        style: textTheme.titleMedium?.copyWith(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        poiLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Poppins',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (distanceLabel != '--') ...[
                        const SizedBox(height: 12),
                        buildInfoChip(
                          icon: Icons.map_outlined,
                          label: '$distanceLabel km',
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 250),
                  turns: isSelected ? 0.25 : 0,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// Tarjeta para cada POI que agrupa acciones rápidas (navegar, ver detalles, previsualizar).
    Widget buildPoiCard({
      required dynamic poi,
      required VoidCallback onPreview,
      required VoidCallback onOpenDetail,
      required VoidCallback onNavigate,
    }) {
      final loc = AppLocalizations.of(context)!;
      final String categoryLabel =
          (poi.categorias is List && (poi.categorias as List).isNotEmpty)
          ? (poi.categorias.first as String)
          : '';

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPreview,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poi.nombre,
                            style: textTheme.titleMedium?.copyWith(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (categoryLabel.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              categoryLabel,
                              style: textTheme.bodySmall?.copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.navigation_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onNavigate,
                        label: Text(
                          loc.iniciar_ruta,
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: primaryColor,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onOpenDetail,
                        label: Text(
                          loc.ver_detalles,
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// Vista cuando el sheet muestra la lista de rutas disponibles.
    Widget buildRoutesView() {
      if (!isLoaded) {
        return buildSheetListView(
          key: const ValueKey<String>('loading-routes'),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      }

      if (filteredRoutes.isEmpty) {
        return buildSheetListView(
          key: const ValueKey<String>('empty-routes'),
          children: [
            buildEmptyState(
              icon: Icons.alt_route_rounded,
              title: AppLocalizations.of(context)!.sin_resultado,
              description: AppLocalizations.of(context)!.rutas_disponibles,
            ),
          ],
        );
      }

      return ListView.separated(
        key: const ValueKey<String>('routes-list'),
        controller: scrollController,
        physics: _sheetScrollPhysics,
        padding: _sheetContentPadding,
        itemBuilder: (context, index) {
          final route = filteredRoutes[index];
          return buildRouteCard(route: route, index: index);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: filteredRoutes.length,
      );
    }

    /// Vista de detalle que lista los POIs de la ruta seleccionada.
    Widget buildSelectedRouteView() {
      if (!isLoaded || selectedRoute == null) {
        return buildSheetListView(
          key: const ValueKey<String>('pending-pois'),
          children: [
            buildEmptyState(
              icon: Icons.place_outlined,
              title: AppLocalizations.of(context)!.sin_resultado,
              description: AppLocalizations.of(context)!.resultado_busqueda,
            ),
          ],
        );
      }

      final List<dynamic> pois = (selectedRoute.pois is List)
          ? (selectedRoute.pois as List)
          : [];

      if (pois.isEmpty) {
        return buildSheetListView(
          key: const ValueKey<String>('empty-pois'),
          children: [
            buildEmptyState(
              icon: Icons.place_outlined,
              title: AppLocalizations.of(context)!.sin_resultado,
              description: AppLocalizations.of(context)!.resultado_busqueda,
            ),
          ],
        );
      }

      return ListView.separated(
        key: const ValueKey<String>('poi-list'),
        controller: scrollController,
        physics: _sheetScrollPhysics,
        padding: _sheetContentPadding,
        itemBuilder: (context, index) {
          final poi = pois[index];
          return buildPoiCard(
            poi: poi,
            onPreview: () {
              onMoveMap(LatLng(poi.latitud, poi.longitud), zoom: 16);
            },
            onOpenDetail: () {
              // Analytics: abrir POI desde detalle de ruta
              AnalyticsService.logAbrirPOI(poi.id, poi.nombre);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PoiScreen(poi)),
              );
            },
            onNavigate: () {
              context.read<MapBloc>().add(
                RequestNavigation(
                  LatLng(poi.latitud, poi.longitud),
                  Localizations.localeOf(context).languageCode,
                ),
              );
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: pois.length,
      );
    }

    /// Vista de resultados cuando se realiza una búsqueda sobre rutas o POIs.
    Widget buildSearchView() {
      if (!isLoaded) {
        return buildSheetListView(
          key: const ValueKey<String>('loading-search'),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      }

      if (filteredRoutes.isEmpty && filteredPois.isEmpty) {
        return buildSheetListView(
          key: const ValueKey<String>('empty-search'),
          children: [
            buildEmptyState(
              icon: Icons.search_off_rounded,
              title: AppLocalizations.of(context)!.sin_resultado,
              description: query.isEmpty
                  ? AppLocalizations.of(context)!.resultado_busqueda
                  : '"$query"',
            ),
          ],
        );
      }

      return buildSheetListView(
        key: const ValueKey<String>('results-search'),
        children: [
          if (filteredRoutes.isNotEmpty) ...[
            buildSectionTitle(AppLocalizations.of(context)!.rutas_disponibles),
            const SizedBox(height: 12),
            ...List.generate(filteredRoutes.length, (index) {
              final route = filteredRoutes[index];
              final bool isLastRoute =
                  index == filteredRoutes.length - 1 && filteredPois.isEmpty;
              return Padding(
                padding: EdgeInsets.only(bottom: isLastRoute ? 0 : 12),
                child: buildRouteCard(route: route, index: index),
              );
            }),
            if (filteredPois.isNotEmpty) const SizedBox(height: 24),
          ],
          if (filteredPois.isNotEmpty) ...[
            buildSectionTitle(AppLocalizations.of(context)!.resultado_busqueda),
            const SizedBox(height: 12),
            ...List.generate(filteredPois.length, (index) {
              final poi = filteredPois[index];
              final bool isLastPoi = index == filteredPois.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLastPoi ? 0 : 12),
                child: buildPoiCard(
                  poi: poi,
                  onPreview: () {
                    onMoveMap(LatLng(poi.latitud, poi.longitud), zoom: 16);
                  },
                  onOpenDetail: () {
                    // Analytics: abrir POI desde resultados de búsqueda
                    AnalyticsService.logAbrirPOI(poi.id, poi.nombre);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PoiScreen(poi)),
                    );
                  },
                  onNavigate: () {
                    context.read<MapBloc>().add(
                      RequestNavigation(
                        LatLng(poi.latitud, poi.longitud),
                        Localizations.localeOf(context).languageCode,
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ],
      );
    }

    String headerTitle;
    if (hasSearch) {
      headerTitle = AppLocalizations.of(context)!.resultado_busqueda;
    } else if (selectedRoute == null) {
      headerTitle = AppLocalizations.of(context)!.rutas_disponibles;
    } else {
      headerTitle =
          '${AppLocalizations.of(context)!.ruta} ${selectedRoute.name}';
    }

    final List<Widget> headerChips = [];
    if (hasSearch) {
      if (query.isNotEmpty) {
        headerChips.add(
          buildInfoChip(icon: Icons.search_rounded, label: '"$query"'),
        );
      }
      if (filteredRoutes.isNotEmpty) {
        final String routeLabel = AppLocalizations.of(
          context,
        )!.ruta.toLowerCase();
        final int count = filteredRoutes.length;
        headerChips.add(
          buildInfoChip(
            icon: Icons.alt_route_rounded,
            label: '$count $routeLabel${count == 1 ? '' : 's'}',
          ),
        );
      }
      if (filteredPois.isNotEmpty) {
        final int count = filteredPois.length;
        headerChips.add(
          buildInfoChip(
            icon: Icons.place_rounded,
            label: '$count POI${count == 1 ? '' : 's'}',
          ),
        );
      }
    } else if (selectedRoute == null) {
      final String routeLabel = AppLocalizations.of(
        context,
      )!.ruta.toLowerCase();
      final int count = filteredRoutes.length;
      headerChips.add(
        buildInfoChip(
          icon: Icons.alt_route_rounded,
          label: '$count $routeLabel${count == 1 ? '' : 's'}',
        ),
      );
    } else {
      final List<dynamic> pois = (selectedRoute.pois is List)
          ? (selectedRoute.pois as List)
          : [];
      final int poiCount = pois.length;
      headerChips.add(
        buildInfoChip(
          icon: Icons.place_rounded,
          label: '$poiCount POI${poiCount == 1 ? '' : 's'}',
        ),
      );

      final double? distanceKm = selectedRoute.distanceKm is num
          ? (selectedRoute.distanceKm as num?)?.toDouble()
          : null;
      if (distanceKm != null && distanceKm > 0) {
        final String distanceLabel = distanceKm >= 10
            ? distanceKm.toStringAsFixed(0)
            : distanceKm.toStringAsFixed(1);
        headerChips.add(
          buildInfoChip(icon: Icons.map_outlined, label: '$distanceLabel km'),
        );
      }
    }

    /// Manipula el tamaño del [DraggableScrollableSheet] durante el arrastre manual.
    void handleDragUpdate(DragUpdateDetails details) {
      if (!draggableController.isAttached) {
        return;
      }
      final double primaryDelta = details.primaryDelta ?? 0;
      if (primaryDelta == 0) {
        return;
      }
      final double minPixels = draggableController.sizeToPixels(minChildSize);
      final double maxPixels = draggableController.sizeToPixels(maxChildSize);
      final double currentPixels = draggableController.pixels;
      final double updatedPixels = currentPixels - primaryDelta;
      final double clampedPixels = updatedPixels
          .clamp(minPixels, maxPixels)
          .toDouble();
      final double newSize = draggableController.pixelsToSize(clampedPixels);
      draggableController.jumpTo(newSize);
    }

    /// Ajusta el tamaño del sheet al punto de snap más cercano tras soltar el arrastre.
    void handleDragEnd(DragEndDetails details) {
      if (!draggableController.isAttached) {
        return;
      }
      final Set<double> snapCandidates = {minChildSize, maxChildSize, 0.4};
      final List<double> snapSizes =
          snapCandidates
              .where((size) => size >= minChildSize && size <= maxChildSize)
              .toList()
            ..sort();
      if (snapSizes.isEmpty) {
        return;
      }
      final double currentSize = draggableController.size;
      double targetSize = snapSizes.first;
      double smallestDistance = (currentSize - targetSize).abs();
      for (final double size in snapSizes) {
        final double distance = (currentSize - size).abs();
        if (distance < smallestDistance) {
          smallestDistance = distance;
          targetSize = size;
        }
      }
      final double clampedTarget = targetSize
          .clamp(minChildSize, maxChildSize)
          .toDouble();
      if ((currentSize - clampedTarget).abs() < 0.001) {
        return;
      }
      draggableController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }

    return AnimatedPadding(
      // Padding animado que reserva el espacio del teclado para evitar "BOTTOM OVERFLOWED" sin alterar la estética.
      padding: EdgeInsets.only(bottom: keyboardInset),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.96 : 0.94,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: handleDragUpdate,
                onVerticalDragEnd: handleDragEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: handleDragUpdate,
              onVerticalDragEnd: handleDragEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedRoute != null) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withAlpha(28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onClearSelectedRoute,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              headerTitle,
                              key: ValueKey<String>(headerTitle),
                              style: textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (headerChips.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: headerChips,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: hasSearch
                    ? KeyedSubtree(
                        key: const ValueKey<String>('search-view'),
                        child: buildSearchView(),
                      )
                    : selectedRoute == null
                    ? KeyedSubtree(
                        key: const ValueKey<String>('routes-view'),
                        child: buildRoutesView(),
                      )
                    : KeyedSubtree(
                        key: const ValueKey<String>('poi-view'),
                        child: buildSelectedRouteView(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
