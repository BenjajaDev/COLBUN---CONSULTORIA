import 'package:flutter/material.dart';
import 'package:consultoria_chat_bot/services/local_storage.dart';
import 'package:consultoria_chat_bot/l10n/app_localizations.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<EmergencyContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contacts = await LocalStorage.getEmergencyContacts();
    setState(() {
      _contacts = contacts;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title: Text(AppLocalizations.of(context)!.emergencias_title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              AppLocalizations.of(context)!.telefonos_emergencia_title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final loc = AppLocalizations.of(context)!;
                final List<EmergencyContact> data = _contacts.isNotEmpty
                    ? _contacts
                    : <EmergencyContact>[
                        EmergencyContact(
                          name: loc.emergency_police_chile,
                          phone: '133',
                        ),
                        EmergencyContact(
                          name: loc.emergency_firefighters_chile,
                          phone: '132',
                        ),
                        EmergencyContact(
                          name: loc.emergency_ambulance_chile,
                          phone: '131',
                        ),
                      ];

                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = data[index];
                    return ListTile(
                      leading: const Icon(Icons.call, color: Colors.red),
                      title: Text(c.name),
                      subtitle: Text(c.phone),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
