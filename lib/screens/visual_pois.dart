import 'dart:async';
import 'package:flutter/material.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// ==================== ESTADOS DEL BLOC ====================
abstract class DescripcionState {
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];
}

String obtenerTraduccion(BuildContext context, String id) {
  final loc = AppLocalizations.of(context)!;
  switch (id) {
    case 'galeriaArteNatural':
      return loc.galeriaArteNatural;
    case 'armerillo':
      return loc.armerillo;
    case 'pasoNevado':
      return loc.pasoNevado;
    case 'pagina4':
      return loc.pagina4;
    case 'pagina5':
      return loc.pagina5;
    default:
      return id;
  }
}

class DescripcionInitial extends DescripcionState {}

class DescripcionLoaded extends DescripcionState {
  final List<String> idBotones;
  DescripcionLoaded(this.idBotones);

  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);
}

// ==================== EVENTOS DEL BLOC ====================
abstract class DescripcionEvent {}

class LoadDescripcion extends DescripcionEvent {}

// ==================== BLOC SENCILLO ====================
class DescripcionBloc {
  final _stateController = StreamController<DescripcionState>.broadcast();
  final _eventController = StreamController<DescripcionEvent>();

  Stream<DescripcionState> get state => _stateController.stream;
  Sink<DescripcionEvent> get eventSink => _eventController.sink;

  DescripcionBloc() {
    _eventController.stream.listen(_mapEventToState);
  }

  void _mapEventToState(DescripcionEvent event) {
    if (event is LoadDescripcion) {
      _stateController.add(
        DescripcionLoaded([
          'galeriaArteNatural',
          'armerillo',
          'pasoNevado',
          'pagina4',
          'pagina5',
        ]),
      );
    }
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}

// ==================== VISTA PRINCIPAL ====================
class DescripcionPOIs extends StatefulWidget {
  const DescripcionPOIs({super.key});
  @override
  State<DescripcionPOIs> createState() => _DescripcionPOIsState();
}

class _DescripcionPOIsState extends State<DescripcionPOIs> {
  bool _isFavorito = false;
  late final DescripcionBloc bloc;
  final String url =
      "https://upload.wikimedia.org/wikipedia/commons/2/2f/Letrero_Las_Vizcachas_de_Rari.jpg";
  String? valorSeleccionado = 'Otoño';
  final List<String> opciones = ['Otoño', 'Invierno', 'Primavera', 'Verano'];

  // Overlay (info)
  OverlayEntry? _overlayEntry;
  final GlobalKey _iconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    bloc = DescripcionBloc();
    bloc.eventSink.add(LoadDescripcion());
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    bloc.dispose();
    super.dispose();
  }

  void _togglefavorito() {
    setState(() {
      _isFavorito = !_isFavorito;
    });
  }

  void _showOverlay() {
    // remove any existing
    _overlayEntry?.remove();
    _overlayEntry = null;

    final renderBox = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    // Compute left but clamp to screen edges
    double left = offset.dx - 110; // center-ish to the left of the icon
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

    // auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DescripcionState>(
          stream: bloc.state,
          builder: (context, snapshot) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ==================== TITULO + BOTON X ====================
                            Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.8,
                                  padding: const EdgeInsets.all(8),
                                  child: const Text(
                                    "Parque Las Vizcachas de Rari",
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.2,
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    label: const Icon(
                                      Icons.close,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ==================== IMAGEN PRINCIPAL ====================
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 250,
                              ),
                            ),

                            // ==================== BOTONES DE ACTIVIDADES ====================
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(10),
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[50],
                                        ),
                                        child: const Text(
                                          "Trekking",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(10),
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[50],
                                        ),
                                        child: const Text(
                                          "Naturaleza",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    child: IconButton(
                                      icon: Icon(
                                        _isFavorito
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: _isFavorito
                                            ? Colors.pink
                                            : Colors.grey,
                                      ),
                                      onPressed: _togglefavorito,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ==================== DROPDOWN + INFO + VISTA 360 + BOTON EMERGENCIA ====================
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  DropdownButton<String>(
                                    value: valorSeleccionado,
                                    items: opciones.map((String opcion) {
                                      return DropdownMenuItem<String>(
                                        value: opcion,
                                        child: Text(opcion),
                                      );
                                    }).toList(),
                                    onChanged: (String? nuevoValor) {
                                      setState(() {
                                        valorSeleccionado = nuevoValor;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      print("Vista 360");
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    child: const Text(
                                      "Vista 360",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),

                                  // Icono de información con overlay
                                  const SizedBox(width: 8),
                                  IconButton(
                                    key: _iconKey,
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      // toggle overlay
                                      if (_overlayEntry == null) {
                                        _showOverlay();
                                      } else {
                                        _overlayEntry?.remove();
                                        _overlayEntry = null;
                                      }
                                    },
                                  ),

                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      print("Emergencia");
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(14),
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

                            // ==================== DESCRIPCION ====================
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              child: Text(
                                "Descripción:",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                "El Parque Las Vizcachas de Rari es un centro recreativo familiar en la comuna de Colbún, con piscinas, áreas de picnic y camping, rodeado de naturaleza y cercano a atractivos como el Lago Colbún y las artesanías en crin de Rari.",
                              ),
                            ),

                            // ==================== RECOMENDADOS ====================
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              child: Text(
                                "Recomendados",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: constraints.maxHeight * 0.4,
                              child: snapshot.data is DescripcionLoaded
                                  ? DescripcionPOIView(
                                      idBotones:
                                          (snapshot.data as DescripcionLoaded)
                                              .idBotones,
                                      onBotonPressed: (texto) {
                                        print("Presionaste: $texto");
                                      },
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ==================== VISTA DE LOS BOTONES RECOMENDADOS ====================

class DescripcionPOIView extends StatefulWidget {
  final List<String> idBotones;
  final Function(String) onBotonPressed;

  const DescripcionPOIView({
    super.key,
    required this.idBotones,
    required this.onBotonPressed,
  });

  @override
  State<DescripcionPOIView> createState() => _DescripcionPOIViewState();
}

class _DescripcionPOIViewState extends State<DescripcionPOIView> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PageView
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.idBotones.length,
            itemBuilder: (_, index) {
              final texto = obtenerTraduccion(context, widget.idBotones[index]);
              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: TextButton(
                    onPressed: () => widget.onBotonPressed(texto),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          texto,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Detalle para $texto",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Indicador de páginas
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _controller,
          count: widget.idBotones.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            spacing: 6,
            activeDotColor: Colors.blue,
            dotColor: Colors.grey,
          ),
        ),
      ],
    );
  }
}
