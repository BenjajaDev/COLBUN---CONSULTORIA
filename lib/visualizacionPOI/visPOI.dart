import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Material App', home: DescripcionPOIs());
  }
}

class DescripcionPOIs extends StatefulWidget {
  const DescripcionPOIs({super.key});
  @override
  State<DescripcionPOIs> createState() => _DescripcionPOIsState();
}

class _DescripcionPOIsState extends State<DescripcionPOIs> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _iconKey = GlobalKey();

  final String url =
      "https://upload.wikimedia.org/wikipedia/commons/2/2f/Letrero_Las_Vizcachas_de_Rari.jpg";
  final PageController _controller = PageController();
  final int _numPages = 5;
  final List<String> opciones = ['Otoño', 'Invierno', 'Primavera', 'Verano'];
  final List<String> textosBotones = [
    "Galeria de Arte Natural",
    "Armerillo",
    "Paso Nevado",
    "Botón Página 4",
    "Botón Página 5",
  ];

  String? valorSeleccionado = 'Otoño';

  void _showOverlay() {
    final renderBox = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: offset.dx - 50,
        top: offset.dy + size.height + 5,
        child: Material(
          color: Colors.transparent,
          child: Container(
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

    overlay.insert(_overlayEntry!);

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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth * 0.8,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Parque Las Vizcachas de Rari",
                    style: TextStyle(fontSize: 25, color: Colors.black),
                  ),
                ),
                Container(
                  width: screenWidth * 0.2,
                  height: 50,
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () {
                      print("Saliste");
                    },
                    label: const Icon(Icons.close, color: Colors.black),
                    onLongPress: null,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: Image.network(url, fit: BoxFit.contain),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.all(15),
                    padding: const EdgeInsetsDirectional.all(8),
                    height: screenWidth * 0.11,

                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        print("Trekking");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                      ),
                      child: Text(
                        "Trekking",
                        style: TextStyle(fontSize: 20, color: Colors.blue),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(15),
                    padding: const EdgeInsetsDirectional.all(8),
                    height: screenWidth * 0.11,

                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        print("Naturaleza");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                      ),
                      child: Text(
                        "Naturaleza",
                        style: TextStyle(fontSize: 20, color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: DropdownButton<String>(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        print("vista 360");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        "Vista 360",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  IconButton(
                    key: _iconKey,
                    icon: const Icon(Icons.info_outline, color: Colors.black),
                    onPressed: () {
                      if (_overlayEntry == null) {
                        _showOverlay();
                      }
                    },
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          print("Boton de emergencia");
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.red,
                        ),
                        label: const Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SizedBox(
                width: double.infinity,
                child: const Text(
                  "Descripcion:",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const SizedBox(
                width: double.infinity,
                child: Text(
                  "El Parque Las Vizcachas de Rari es un centro recreativo familiar en la comuna de Colbún, con piscinas, áreas de picnic y camping, rodeado de naturaleza y cercano a atractivos como el Lago Colbún y las artesanías en crin de Rari.",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const SizedBox(
                width: double.infinity,
                child: Text(
                  "Recomendados",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _numPages,
                itemBuilder: (_, index) {
                  return Container(
                    color: Colors.white,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          print('presionaste ${textosBotones[index]}');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                        ),
                        child: Text(
                          textosBotones[index],
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
