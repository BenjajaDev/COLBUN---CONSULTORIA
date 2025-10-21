import 'package:consultoria_chat_bot/blocs/poi_bloc.dart';
import 'package:consultoria_chat_bot/blocs/favorites_cubit.dart';
import 'package:consultoria_chat_bot/events/poi_event.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/states/panorama_screen.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:consultoria_chat_bot/states/map_state.dart';
import 'package:consultoria_chat_bot/blocs/map_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PoiScreen extends StatefulWidget {
  final POI poi;
  const PoiScreen(this.poi, {super.key});

  @override
  State<PoiScreen> createState() => _PoiScreenState();
}

class _PoiScreenState extends State<PoiScreen> {
  Color colbunBlue = const Color(0xFF4D67AE);
  int _selectedIndex = 0;
  String? valorSeleccionado = 'Otoño';
  final List<String> opciones = ['Otoño', 'Invierno', 'Primavera', 'Verano'];
  

  // Tooltip text previously pulled from l10n; keep ARB updated and run `flutter gen-l10n` to generate accessors.

  // Add controllers and page state for pagination
  final PageController _recomendadosController = PageController();
  final PageController _cercanosController = PageController();
  int _recomendadosPage = 0;
  int _cercanosPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapState = context.read<MapBloc>().state;

      List<POI> allPois = [];
      LatLng? userLoc;

      if (mapState is MapLoaded) {
        for (final r in mapState.allRoutes) {
          allPois.addAll(r.pois);
        }
        userLoc = mapState.userLocation;
      }

      context.read<PoiBloc>().add(
        LoadPoi(current: widget.poi, all: allPois, userLocation: userLoc),
      );
    });

    _recomendadosController.addListener(() {
      final page = _recomendadosController.page?.round() ?? 0;
      if (page != _recomendadosPage) setState(() => _recomendadosPage = page);
    });
    _cercanosController.addListener(() {
      final page = _cercanosController.page?.round() ?? 0;
      if (page != _cercanosPage) setState(() => _cercanosPage = page);
    });
  }

  @override
  void dispose() {
    _recomendadosController.dispose();
    _cercanosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MapBloc, MapState>(
      listenWhen: (prev, curr) => curr is MapLoaded,
      listener: (context, state) {
        final m = state as MapLoaded;
        final allPois = m.allRoutes.expand((r) => r.pois).toList();

        context.read<PoiBloc>().add(
          LoadPoi(
            current: widget.poi,
            all: allPois,
            userLocation: m.userLocation,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return BlocBuilder<PoiBloc, PoiState>(
                builder: (context, state) {
                  if (state is PoiLoaded) {
                    final recList = state.recommended;
                    final nearList = state.nearby;
                    final dkm = state.distancesKm;
                    final List<Map<String, dynamic>> items = [
                      ...state.categorias,
                      ...state.actividades,
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================== TITULO + BOTON X ====================
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  widget.poi.nombre,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),

                        // ==================== IMAGEN PRINCIPAL ====================
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Image.network(
                                  widget.poi.imagen,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.poi.imagen,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250,
                            ),
                          ),
                        ),

                        // ==================== Categorias y actividades ====================
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Lista de chips horizontal
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: items.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      return ActionChip(
                                    label: Text(
                                      items[index]['nombre'][Localizations.localeOf(
                                            context,
                                          ).languageCode] ?? items[index]['nombre']['es'] 
                                          ,
                                      style: TextStyle(
                                        color:
                                            getColorFromHex(items[index]['text_color'].toString()),
                                      ),
                                    ),
                                    backgroundColor:
                                        getColorFromHex(items[index]['background_color'].toString()),
                                    side: BorderSide.none,
                                    onPressed: () {},
                                  );
                                    },
                                  ),
                                ),
                              ),

                              // Icono de favorito
                              BlocBuilder<FavoritesCubit, FavoritesState>(
                                builder: (context, favoritesState) {
                                  final isFavorite = favoritesState.contains(
                                    widget.poi.id,
                                  );
                                  return IconButton(
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.pink
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      context
                                          .read<FavoritesCubit>()
                                          .toggleFavorite(widget.poi);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // ==================== DROPDOWN + INFO + VISTA 360 + BOTON EMERGENCIA ====================
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Dropdown with rounded black border
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.3,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white,
                                ),
                                child: DropdownButton<String>(
                                  value: valorSeleccionado,
                                  underline: SizedBox(),
                                  borderRadius: BorderRadius.circular(18),
                                  items: opciones.map((String opcion) {
                                    IconData icon;
                                    Color iconColor;
                                    switch (opcion) {
                                      case 'Otoño':
                                        icon = Icons.park;
                                        iconColor = Colors.orange;
                                        break;
                                      case 'Invierno':
                                        icon = Icons.ac_unit;
                                        iconColor = Colors.lightBlue;
                                        break;
                                      case 'Primavera':
                                        icon = Icons.eco_outlined;
                                        iconColor = Colors.green;
                                        break;
                                      case 'Verano':
                                        icon = Icons.wb_sunny;
                                        iconColor = Colors.amber;
                                        break;
                                      default:
                                        icon = Icons.circle;
                                        iconColor = Colors.black54;
                                    }

                                    // Determine if this season has a non-empty panorama image
                                    final Map<String, dynamic> vistas = widget.poi.vistas360;
                                    final hasImage = vistas.containsKey(opcion) &&
                                        (vistas[opcion] != null && vistas[opcion].toString().trim().isNotEmpty);

                                    // Visually dim disabled options
                                    final textStyle = hasImage
                                        ? const TextStyle(color: Colors.black)
                                        : TextStyle(color: Colors.black.withOpacity(0.35));
                                    final iconColorEffective = hasImage ? iconColor : iconColor.withOpacity(0.35);

                                    // localized label for display (falls back to Spanish via AppLocalizations)
                                    String localizedLabel() {
                                      final loc = AppLocalizations.of(context)!;
                                      switch (opcion) {
                                        case 'Otoño':
                                          return loc.otono;
                                        case 'Invierno':
                                          return loc.invierno;
                                        case 'Primavera':
                                          return loc.primavera;
                                        case 'Verano':
                                          return loc.verano;
                                        default:
                                          return opcion;
                                      }
                                    }

                                    return DropdownMenuItem<String>(
                                      value: opcion,
                                      enabled: hasImage,
                                      child: Row(
                                        children: [
                                          Icon(
                                            icon,
                                            size: 20,
                                            color: iconColorEffective,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(localizedLabel(), style: textStyle),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? nuevoValor) {
                                    // If the user attempts to pick a season without an image, show a SnackBar and ignore
                                    if (nuevoValor == null) return;
                                    final Map<String, dynamic> vistas = widget.poi.vistas360;
                                    final hasImage = vistas.containsKey(nuevoValor) &&
                                        (vistas[nuevoValor] != null && vistas[nuevoValor].toString().trim().isNotEmpty);
                                    if (!hasImage) {
                                      final locLabel = () {
                                        final loc = AppLocalizations.of(context)!;
                                        switch (nuevoValor) {
                                          case 'Otoño':
                                            return loc.otono;
                                          case 'Invierno':
                                            return loc.invierno;
                                          case 'Primavera':
                                            return loc.primavera;
                                          case 'Verano':
                                            return loc.verano;
                                          default:
                                            return nuevoValor;
                                        }
                                      }();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('No hay imagen 360 para la temporada "$locLabel".')),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      valorSeleccionado = nuevoValor;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // try to get the panorama for the selected season
                                  final Map<String, dynamic> vistas = widget.poi.vistas360;
                                  final seasonKey = valorSeleccionado ?? '';
                                  String? imagePath;

                                  if (seasonKey.isNotEmpty && vistas.containsKey(seasonKey)) {
                                    final v = vistas[seasonKey];
                                    if (v != null) imagePath = v.toString();
                                  }

                                  // fallback: take the first available image if any
                                  if (imagePath == null && vistas.isNotEmpty) {
                                    final first = vistas.values.firstWhere(
                                      (v) => v != null,
                                      orElse: () => null,
                                    );
                                    if (first != null) imagePath = first.toString();
                                  }

                                  if (imagePath == null || imagePath.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No hay imagen 360 disponible para la temporada seleccionada.')),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PanoramaScreen(
                                        imagePath: imagePath!,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colbunBlue,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.vista360,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Tooltip(
                                message: AppLocalizations.of(context)!.vistas_modificadas_ia,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    // show localized SnackBar for accessibility
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppLocalizations.of(context)!.vistas_modificadas_ia)),
                                    );
                                  },
                                ),
                              ),
                              Spacer(),
                              ElevatedButton.icon(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  backgroundColor: Colors.red,
                                ),
                                label: const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ListView(
                            children: [
                              //=================Estacion actual========================
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Temporada actual: Primavera \nClima templado, flora abundante, ideal para trekking",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colbunBlue,
                                    ),
                                  ),
                                ),
                              ),
                              // ==================== DESCRIPCION ====================
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.descripcion,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Text(
                                  widget.poi.descripcion[Localizations.localeOf(
                                        context,
                                      ).languageCode] ??
                                      widget.poi.descripcion['es'] ??
                                      '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),

                              //Tabs Recomendados / Cerca de ti
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _selectedIndex == 0
                                                ? colbunBlue
                                                : Colors.black,
                                            width: _selectedIndex == 0 ? 3 : 1,
                                          ),
                                        ),
                                      ),
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              0,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedIndex = 0;
                                          });
                                        },
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.recomendados,
                                          style: TextStyle(
                                            color: _selectedIndex == 0
                                                ? colbunBlue
                                                : Colors.black,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _selectedIndex == 1
                                                ? colbunBlue
                                                : Colors.black,
                                            width: _selectedIndex == 1 ? 3 : 1,
                                          ),
                                        ),
                                      ),
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              0,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedIndex = 1;
                                          });
                                        },
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.cercanos,
                                          style: TextStyle(
                                            color: _selectedIndex == 1
                                                ? colbunBlue
                                                : Colors.black,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ==================== RECOMENDADOS ====================
                              if (_selectedIndex == 0)
                                Column(
                                  children: [
                                    if (recList.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Sin recomendados para este POI',
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 140,
                                        child: PageView.builder(
                                          controller: _recomendadosController,
                                          itemCount: state
                                              .recommended
                                              .length, //vinculado al estado
                                          itemBuilder: (context, index) {
                                            final rec = state
                                                .recommended[index]; //usa datos del estado
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: SizedBox(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width -
                                                    48,
                                                child: InkWell(
                                                  onTap: () {
                                                    // 1) Traer todos los POIs + ubicacion desde MapBloc
                                                    final mapState = context
                                                        .read<MapBloc>()
                                                        .state;
                                                    List<POI> allPois = [];
                                                    LatLng? userLoc;

                                                    if (mapState is MapLoaded) {
                                                      for (final r
                                                          in mapState
                                                              .allRoutes) {
                                                        allPois.addAll(r.pois);
                                                      }
                                                      userLoc =
                                                          mapState.userLocation;
                                                    }

                                                    // 2) Despachar el evento al PoiBloc
                                                    context.read<PoiBloc>().add(
                                                      LoadPoi(
                                                        current: rec,
                                                        all: allPois,
                                                        userLocation: userLoc,
                                                      ),
                                                    );

                                                    // 3) Navegar a la ficha del POI
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            PoiScreen(rec),
                                                      ),
                                                    );
                                                  },
                                                  child: Card(
                                                    margin: EdgeInsets.zero,
                                                    color: const Color(
                                                      0xFFF4F4F4,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            rec.nombre,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Wrap(
                                                            spacing: 6,
                                                            children: rec.categorias.map((
                                                              cat,
                                                            ) {
                                                              return Chip(
                                                                label: Text(
                                                                  cat,
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        16,
                                                                      ),
                                                                  side: BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade300,
                                                                  ),
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        state
                                            .recommended
                                            .length, //  indicadores ligados al estado
                                        (i) => Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _recomendadosPage == i
                                                ? colbunBlue
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else // ---------------- CERCA DE TI ----------------
                                Column(
                                  children: [
                                    if (nearList.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text('Sin lugares cerca.'),
                                      )
                                    else
                                      SizedBox(
                                        height: 140,
                                        child: PageView.builder(
                                          controller: _cercanosController,
                                          itemCount: state
                                              .nearby
                                              .length, //vinculado al estado
                                          itemBuilder: (context, index) {
                                            final p = state
                                                .nearby[index]; //usa datos del estado
                                            final double? km =
                                                dkm[p
                                                    .id]; //  distancia para subtitulo
                                            final String? subtitleText =
                                                km == null
                                                ? null
                                                : "${km.toStringAsFixed(1)} km"; // formato texto km
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: SizedBox(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width -
                                                    48,
                                                child: Card(
                                                  margin: EdgeInsets.zero,
                                                  color: const Color(
                                                    0xFFF4F4F4,
                                                  ),
                                                  child: ListTile(
                                                    title: Text(p.nombre),
                                                    subtitle:
                                                        subtitleText == null
                                                        ? null
                                                        : Text(subtitleText),
                                                    onTap: () {
                                                      final mapState = context
                                                          .read<MapBloc>()
                                                          .state;
                                                      List<POI> allPois = [];
                                                      LatLng? userLoc;

                                                      if (mapState
                                                          is MapLoaded) {
                                                        for (final r
                                                            in mapState
                                                                .allRoutes) {
                                                          allPois.addAll(
                                                            r.pois,
                                                          );
                                                        }
                                                        userLoc = mapState
                                                            .userLocation;
                                                      }

                                                      context
                                                          .read<PoiBloc>()
                                                          .add(
                                                            LoadPoi(
                                                              current: p,
                                                              all: allPois,
                                                              userLocation:
                                                                  userLoc,
                                                            ),
                                                          );
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              PoiScreen(p),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        state
                                            .nearby
                                            .length, // indicadores ligados al estado
                                        (i) => Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _cercanosPage == i
                                                ? colbunBlue
                                                : Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Color getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor"; // add alpha if missing
      }
      if (hexColor.length == 8) {
        return Color(int.parse(hexColor, radix: 16));
      }
      return Colors.transparent;
    } catch (e) {
      return Colors.transparent;
    }
  }
}
