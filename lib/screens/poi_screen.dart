import 'package:consultoria_chat_bot/blocs/poi_bloc.dart';
import 'package:consultoria_chat_bot/states/poi_state.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class PoiScreen extends StatefulWidget {
  const PoiScreen({super.key});

  @override
  State<PoiScreen> createState() => _PoiScreenState();
}

class _PoiScreenState extends State<PoiScreen> {
  bool _isFavorito = false;
  String? valorSeleccionado = 'Otoño';
  final List<String> opciones = ['Otoño', 'Invierno', 'Primavera', 'Verano'];

  // Overlay (info)
  OverlayEntry? _overlayEntry;
  final GlobalKey _iconKey = GlobalKey();

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
    return BlocProvider(
      create: (_) => PoiBloc(),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return BlocBuilder<PoiBloc, PoiState>(
                builder: (context, state) {
                  if (state is POI) {
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
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: const Text(
                                          "Parque Las Vizcachas de Rari",
                                          style: TextStyle(
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
                                      builder: (context) {
                                        return Dialog(
                                          child: Image.network(
                                            state.imagen,
                                            fit: BoxFit.contain,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Image.network(
                                    state.imagen,
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
                                        onPressed: () {},
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
                                        onPressed: () {},
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
