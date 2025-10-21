import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PanoramaViewer(
            // Cambia entre giroscopio y control manual
            sensorControl: isGyroEnabled
                ? SensorControl.absoluteOrientation
                : SensorControl.none,
            child: widget.imagePath.startsWith("http")
                ? Image.network(widget.imagePath)
                : Image.asset(widget.imagePath),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Botón para activar/desactivar el giroscopio
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  isGyroEnabled = !isGyroEnabled;
                });
              },
              backgroundColor: Colors.white.withAlpha((0.7*255).round()),
              child: Icon(
                isGyroEnabled
                    ? Icons.screen_rotation
                    : Icons.touch_app,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}