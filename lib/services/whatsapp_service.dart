import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
	WhatsAppService._();

	/// Abre un chat de WhatsApp con el [phone] y [message].
	/// Estrategia:
	/// 1) Intentar con el esquema nativo: whatsapp://send?phone=... (funciona sin internet)
	/// 2) Fallback al enlace web: https://wa.me/... (requiere internet)
	static Future<bool> openChat({
		required String phone,
		required String message,
	}) async {
		final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
		if (digits.isEmpty) return false;

		final appUri = Uri.parse(
			'whatsapp://send?phone=$digits&text=${Uri.encodeComponent(message)}',
		);
		if (await canLaunchUrl(appUri)) {
			return launchUrl(appUri);
		}

		final webUri = Uri.parse(
			'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
		);
		if (await canLaunchUrl(webUri)) {
			return launchUrl(webUri, mode: LaunchMode.externalApplication);
		}
		return false;
	}
}
