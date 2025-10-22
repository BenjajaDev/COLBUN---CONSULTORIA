import 'package:flutter/material.dart';
import 'package:consultoria_chat_bot/services/local_storage.dart';

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
      appBar: AppBar(title: const Text('Emergencias')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Teléfonos de emergencia', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _contacts.isEmpty
                ? const Center(child: Text('Sin datos disponibles'))
                : ListView.separated(
                    itemCount: _contacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = _contacts[index];
                      return ListTile(
                        leading: const Icon(Icons.call, color: Colors.red),
                        title: Text(c.name),
                        subtitle: Text(c.phone),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
