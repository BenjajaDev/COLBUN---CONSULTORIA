import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/screen/auth_screen.dart';
import '../../../features/home/widgets/app_drawer.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:async'; // NEW
import 'package:url_launcher/url_launcher.dart'; // NEW (usado en llamadas tel:)
import '../../../services/whatsapp_service.dart'; // NEW
import '../../../features/chatbot/screen/chatbot_screen.dart'; // NEW
import '../../../services/connectivity_service.dart'; // NEW
import '../../../features/chatbot/bloc/language_block.dart'; // NEW
import '../../../services/firestore_emergency.dart'; // NEW
import '../../../features/chatbot/bloc/theme_bloc.dart'; // NEW: para toggle de tema
import '../../chatbot/utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Si está cargando, muestra un indicador de carga
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Si el usuario está autenticado, muestra la pantalla principal
        if (state is AuthAuthenticated) {
          final l10n = AppLocalizations.of(context);
          final isDark = context.select((ThemeBloc b) => b.state.isDarkMode);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: isDark ? AppColors.darkprimary : AppColors.lightprimary,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                l10n?.appPrincipal ?? 'Principal',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 30, // DS: 28-32 pt para encabezado
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutRequested());
                  },
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${l10n?.bienvenido ?? 'Bienvenido'}, ${state.user.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Email: ${state.user.email}'),

                const SizedBox(height: 16),
                const ConnectionStatusBanner(), // NEW

                const SizedBox(height: 16),
                const LanguageQuickSwitcher(), // NEW

                const SizedBox(height: 16),
                QuickActionsGrid( // NEW
                  onOpenChat: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    );
                  },
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n?.abrirChat ?? 'Abrir chat'),
              backgroundColor:
                  isDark ? AppColors.darkprimary : AppColors.lightprimary,
              foregroundColor: Colors.white,
            ),
          );
        }
        
        // Si el usuario no está autenticado o hay un error, muestra la pantalla de login
        return const AuthScreen();
      },
    );
  }
}

// ---------------- Widgets auxiliares ----------------

// Banner online/offline
class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({super.key});

  @override
  State<ConnectionStatusBanner> createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner> {
  late final ConnectivityService _svc;
  StreamSubscription<bool>? _sub;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _svc = ConnectivityService();
    _init();
  }

  Future<void> _init() async {
    await _svc.initialize();
    if (!mounted) return;
    setState(() => _online = _svc.isOnline);
    _sub = _svc.onConnectivityChanged.listen((v) {
      if (!mounted) return;
      setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _svc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _online ? Colors.green[600] : Colors.amber[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_online ? Icons.wifi : Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _online
                  ? (l10n?.conectado ?? 'Conectado a internet')
                  : (l10n?.sinConexion ?? 'Sin conexión. Modo offline'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Selector rápido de idioma
class LanguageQuickSwitcher extends StatelessWidget {
  const LanguageQuickSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n?.cambiarIdioma ?? 'Cambiar idioma',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: () {
              context.read<LanguageBloc>().add(ChangeLanguage(const Locale('es')));
            }, child: const Text('ES')),
            OutlinedButton(onPressed: () {
              context.read<LanguageBloc>().add(ChangeLanguage(const Locale('en')));
            }, child: const Text('EN')),
            OutlinedButton(onPressed: () {
              context.read<LanguageBloc>().add(ChangeLanguage(const Locale('pt')));
            }, child: const Text('PT')),
          ],
        ),
      ],
    );
  }
}

// Acciones rápidas
// Acciones rápidas
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onOpenChat;
  const QuickActionsGrid({super.key, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16, // DS: múltiplos de 8
      crossAxisSpacing: 16, // DS: múltiplos de 8
      children: [
        _ActionCard(
          icon: Icons.chat_outlined,
          label: l10n?.abrirChat ?? 'Abrir chat',
          onTap: onOpenChat,
        ),
        const _ThemeToggleCard(), // NEW: reemplaza una tarjeta por el switch de tema
        _ActionCard(
          icon: Icons.warning_amber_outlined,
          label: l10n?.emergencias ?? 'Emergencias',
          onTap: () => _openEmergencySheet(context), // NEW: sin registrar en chat
        ),
        _ActionCard(
          icon: Icons.chat,
          label: 'WhatsApp',
          onTap: () => _openWhatsApp(context),
        ),
      ],
    );
  }

  // NEW: BottomSheet con TODOS los números de emergencia (sin tocar el chat)
  Future<void> _openEmergencySheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return const _EmergencyContactsSheet(); // carga asíncrona dentro
      },
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = '+56912345678';
    const message = 'Hola, necesito ayuda.';
    final ok = await WhatsAppService.openChat(phone: phoneNumber, message: message);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }
}
// NEW: Hoja que carga y muestra contactos de emergencia
class _EmergencyContactsSheet extends StatefulWidget {
  const _EmergencyContactsSheet();

  @override
  State<_EmergencyContactsSheet> createState() => _EmergencyContactsSheetState();
}

class _EmergencyContactsSheetState extends State<_EmergencyContactsSheet> {
  final EmergencyService _service = EmergencyService();
  List<EmergencyContact> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Carga desde Firebase y lee la lista local del servicio
      await _service.loadEmergencyContacts();
      if (!mounted) return;
      var loaded = _service.allContacts;
      // Fallback: si no llegó nada de Firestore, intenta desde assets
      if (loaded.isEmpty) {
        await _service.loadEmergencyContactsFromAsset();
        loaded = _service.allContacts;
      }
      setState(() {
        _contacts = loaded;
        _loading = false;
      });
    } catch (e) {
      // Si Firebase lanza error, intentamos el asset como último recurso
      try {
        await _service.loadEmergencyContactsFromAsset();
        if (!mounted) return;
        setState(() {
          _contacts = _service.allContacts;
          _loading = false;
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _error = 'No se pudieron cargar los contactos';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            l10n?.emergencias ?? 'Emergencias',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          else if (_contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n?.sinContactos ?? 'No hay contactos de emergencia'),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _contacts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = _contacts[i];
                  final title = c.getName(langCode);
                  final subtitleType = c.getType(langCode);
                  final phone = c.phone;
                  return ListTile(
                    leading: const Icon(Icons.phone_in_talk),
                    title: Text(title),
                    subtitle: Text(
                      subtitleType.isNotEmpty ? '$subtitleType • $phone' : phone,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: phone.isEmpty ? null : () => _call(phone),
                      tooltip: l10n?.llamar ?? 'Llamar',
                    ),
                    onTap: phone.isEmpty ? null : () => _call(phone),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n?.btnCerrar ?? 'Cerrar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada')),
      );
    }
  }
}
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 32),
                  const SizedBox(height: 8),
                  Text(label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// NEW: Tarjeta con interruptor para cambiar entre tema claro/oscuro
class _ThemeToggleCard extends StatelessWidget {
  const _ThemeToggleCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final isDark = state.isDarkMode;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny, size: 32),
                const SizedBox(height: 8),
                Text(isDark ? AppLocalizations.of(context)?.temaOscuro ?? 'Tema oscuro' : AppLocalizations.of(context)?.temaClaro ?? 'Tema claro', textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Switch(
                  value: isDark,
                  onChanged: (_) {
                    context.read<ThemeBloc>().add(ToggleThemeEvent());
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}