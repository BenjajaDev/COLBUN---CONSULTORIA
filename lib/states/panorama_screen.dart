import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class PanoramaScreen extends StatefulWidget {
  final String imagePath;

  const PanoramaScreen({super.key, required this.imagePath});

  @override
  State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
  // Variable de estado para controlar el giroscopio
  bool isGyroEnabled = false;

  // --- NUEVO: control del overlay de ayuda ---
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    // Allow landscape for panorama experience (and keep portrait up).
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // --- NUEVO: mostrar overlay y ocultarlo automaticamente ---
    // aparece de inmediato y se desvanece a los 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    // Revert to app-wide portrait lock when leaving panorama.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Semantics(
            // Accesibilidad: describe el contenido panoramico.
            label: 'Vista panoramica en 360 grados del lugar seleccionado',
            child: PanoramaViewer(
              sensorControl: isGyroEnabled
                  ? SensorControl.absoluteOrientation
                  : SensorControl.none,
              child: widget.imagePath.startsWith("http")
                  ? Image.network(
                      widget.imagePath,
                      excludeFromSemantics: true,
                    )
                  : Image.asset(
                      widget.imagePath,
                      excludeFromSemantics: true,
                    ),
            ),
          ),

          // Boton cerrar (arriba-derecha)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              // Accesibilidad: describe el boton de cierre.
              tooltip: 'Cerrar vista panoramica',
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Boton para activar/desactivar el giroscopio (abajo-derecha)
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              // Accesibilidad: indica el estado del control.
              tooltip: isGyroEnabled
                  ? 'Desactivar control por giroscopio'
                  : 'Activar control por giroscopio',
              onPressed: () {
                setState(() {
                  isGyroEnabled = !isGyroEnabled;
                });
              },
              backgroundColor: Colors.white.withAlpha((0.7 * 255).round()),
              child: Icon(
                isGyroEnabled ? Icons.screen_rotation : Icons.touch_app,
                color: Colors.blue,
              ),
            ),
          ),

          // Overlay de ayuda con fade (no bloquea los gestos)
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: IgnorePointer(
              ignoring: true, // no intercepta toques
              child: AnimatedOpacity(
                opacity: _showHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Semantics(
                  // Accesibilidad: mensaje audible del overlay.
                  label:
                      'Desliza o mueve tu dispositivo para explorar la vista trescientos sesenta grados',
                  liveRegion: true,
                  child: Center(
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.55),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.touch_app, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Icon(
                              Icons.screen_rotation,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Desliza o mueve tu dispositivo para explorar la vista 360°',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}








