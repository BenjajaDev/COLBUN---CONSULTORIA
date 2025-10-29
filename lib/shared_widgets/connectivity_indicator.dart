import 'package:flutter/material.dart';

/// Indicador visual que muestra cuando la app está en modo offline
class ConnectivityIndicator extends StatelessWidget {
  final bool isOnline;

  const ConnectivityIndicator({
    super.key,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'No hay conexión. Estás en modo offline.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
