import 'package:consultoria_chat_bot/blocs/poi_bloc.dart';
import 'package:consultoria_chat_bot/blocs/favorites_cubit.dart';
import 'package:consultoria_chat_bot/events/poi_event.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:consultoria_chat_bot/model/poi_model.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Pantalla que muestra detalles de un Punto de Interés (POI) con secciones dinámicas y controles.
class PoiScreen extends StatefulWidget {
  final POI poi; // POI cuyos detalles se mostrarán.
  const PoiScreen(this.poi, {super.key});

  @override
  State<PoiScreen> createState() => _PoiScreenState();
}

class _PoiScreenState extends State<PoiScreen> {
  // Color personalizado para la UI.
  Color colbunBlue = const Color(0xFF4D67AE);

  // Índice para controlar selección de pestañas recomendados/cercanos.
  int _selectedIndex = 0;

  // Valor seleccionado del dropdown de temporada.
  String? valorSeleccionado = 'Otoño';

  // Opciones disponibles en el dropdown de temporada.
  final List<String> opciones = ['Otoño', 'Invierno', 'Primavera', 'Verano'];

  // Colores específicos para algunos chips según categoría.
  final Map<String, Map<String, Color>> chipsColors = {
    'naturaleza': {
      'background': Colors.green.shade100,
      'text': Colors.green.shade800,
    },
    'trekking': {
      'background': Colors.brown.shade100,
      'text': Colors.brown.shade800,
    },
  };

  // Datos de ejemplo para secciones recomendados y cercanos (a reemplazar por lógica real).
  List<Map<String, dynamic>> recomendados = [
    {
      'nombre': 'Cascada El Salto',
      'categorias': ['naturaleza', 'aventura'],
      'actividades': [],
    },
    {
      'nombre': 'Mirador Los Andes',
      'categorias': ['paisajes', 'fotografía'],
      'actividades': [],
    },
  ];
  List<Map<String, dynamic>> cercanos = [
    {'nombre': 'Cascada El Salto', 'distancia': 2.5},
    {'nombre': 'Mirador Los Andes', 'distancia': 4.2},
  ];

  // Overlay que muestra información extra al pulsar icono info.
  OverlayEntry? _overlayEntry;
  final GlobalKey _iconKey = GlobalKey();

  // Método que crea y muestra el overlay explicativo.
  void _showOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final renderBox = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calcula la posición horizontal para centrar el overlay respecto al icono, con límites.
    double left = offset.dx - 110;
    if (left < 8) left = 8;
    if (left + 220 > screenWidth - 8) {
      left = screenWidth - 8 - 220;
      if (left < 8) left = 8;
    }

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: left,
        top: offset.dy + size.height + 8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: const Text(
              'Incluye vistas modificadas con IA',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Remueve automáticamente el overlay después de 3 segundos.
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  // Controladores para paginación en listas horizontales recomendados/cercanos.
  final PageController _recomendadosController = PageController();
  final PageController _cercanosController = PageController();
  int _recomendadosPage = 0;
  int _cercanosPage = 0;

  @override
  void initState() {
    super.initState();

    // Solicita cargar datos relacionados al POI al iniciarse la pantalla.
    context.read<PoiBloc>().add(LoadPoi());

    // Escucha cambios de página en recomendados para actualizar indicador.
    _recomendadosController.addListener(() {
      final page = _recomendadosController.page?.round() ?? 0;
      if (page != _recomendadosPage) {
        setState(() {
          _recomendadosPage = page;
        });
      }
    });

    // Escucha cambios de página en cercanos para actualizar indicador.
    _cercanosController.addListener(() {
      final page = _cercanosController.page?.round() ?? 0;
      if (page != _cercanosPage) {
        setState(() {
          _cercanosPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    // Liberar controladores para evitar fugas.
    _recomendadosController.dispose();
    _cercanosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return BlocBuilder<PoiBloc, PoiState>(
              builder: (context, state) {
                // Al cargar correctamente los datos del POI.
                if (state is PoiLoaded) {
                  // Combina categorías y actividades para mostrar con chips.
                  final List<String> items = [
                    ...List<String>.from(widget.poi.categorias),
                    ...List<String>.from(widget.poi.actividades),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ----- TITULO del POI y botón para cerrar la pantalla -----
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
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      // ----- Imagen principal con posibilidad de ampliarla en diálogo -----
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

                      // ----- Chips con categorías y actividades -----
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
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
                                        items[index],
                                        style: TextStyle(
                                          color:
                                              chipsColors[items[index]]?['text'] ??
                                              Colors.black,
                                        ),
                                      ),
                                      backgroundColor:
                                          chipsColors[items[index]]?['background'] ??
                                          Colors.grey.shade200,
                                      side: BorderSide.none,
                                      onPressed: () {},
                                    );
                                  },
                                ),
                              ),
                            ),

                            // ----- Botón favorito que refleja si el POI está marcado -----
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

                      // ----- Fila con dropdown para temporada, botón vista 360, info y botón emergencia -----
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            // Dropdown con las estaciones con íconos y borde redondeado.
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
                                  return DropdownMenuItem<String>(
                                    value: opcion,
                                    child: Row(
                                      children: [
                                        Icon(icon, size: 20, color: iconColor),
                                        const SizedBox(width: 8),
                                        Text(opcion),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? nuevoValor) {
                                  setState(() {
                                    valorSeleccionado = nuevoValor;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Botón para vista 360 del POI.
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colbunBlue,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.vista360,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),

                            // Icono de información (i) que muestra overlay explicativo.
                            IconButton(
                              key: _iconKey,
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                if (_overlayEntry == null) {
                                  _showOverlay();
                                } else {
                                  _overlayEntry?.remove();
                                  _overlayEntry = null;
                                }
                              },
                            ),

                            Spacer(),

                            // Botón circular rojo de llamada de emergencia.
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

                      // ----- Sección expandible con descripción, recomendados y cercanos -----
                      Expanded(
                        child: ListView(
                          children: [
                            // Información de estación actual con texto explicativo.
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

                            // Título descriptivo para la sección de descripción.
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

                            // Texto descriptivo localizado del POI.
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

                            // ----- Pestañas de recomendados / cercanos -----
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Botones para alternar pestañas recomendados / cercanos.
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: _selectedIndex == 0
                                                  ? colbunBlue
                                                  : Colors.black,
                                              width: _selectedIndex == 0
                                                  ? 3
                                                  : 1,
                                            ),
                                          ),
                                        ),
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
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
                                              width: _selectedIndex == 1
                                                  ? 3
                                                  : 1,
                                            ),
                                          ),
                                        ),
                                        child: TextButton(
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
                                  const SizedBox(height: 8),

                                  // Contenido de recomendados o cercanos con paginación y indicador.
                                  if (_selectedIndex == 0) // Recomendados
                                    Column(
                                      children: [
                                        SizedBox(
                                          height: 100,
                                          child: PageView.builder(
                                            controller: _recomendadosController,
                                            itemCount: recomendados.length,
                                            itemBuilder: (context, index) {
                                              final rec = recomendados[index];
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
                                                            rec['nombre']!,
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
                                                            children: List<Widget>.from(
                                                              (rec['categorias']
                                                                      as List)
                                                                  .map(
                                                                    (
                                                                      cat,
                                                                    ) => Chip(
                                                                      label:
                                                                          Text(
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
                                                                    ),
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
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
                                            recomendados.length,
                                            (i) => Container(
                                              width: 8,
                                              height: 8,
                                              margin:
                                                  const EdgeInsets.symmetric(
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
                                  else // Cercanos
                                    Column(
                                      children: [
                                        SizedBox(
                                          height: 100,
                                          child: PageView.builder(
                                            controller: _cercanosController,
                                            itemCount: cercanos.length,
                                            itemBuilder: (context, index) {
                                              final rec = cercanos[index];
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
                                                      title: Text(
                                                        rec['nombre']!,
                                                      ),
                                                      subtitle: Text(
                                                        "${rec['distancia']} km",
                                                      ),
                                                      onTap: () {
                                                        // Acción al tocar POI cercano (pendiente).
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
                                            cercanos.length,
                                            (i) => Container(
                                              width: 8,
                                              height: 8,
                                              margin:
                                                  const EdgeInsets.symmetric(
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
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mostrar loader mientras se cargan datos.
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          },
        ),
      ),
    );
  }
}
