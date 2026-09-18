import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      body: Column(children: [
        const ListTile(
          leading: Icon(Icons.person),
          title: Text('Profile'),
          subtitle: Text('Mechanic Profile'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () async {
            await TokenStorage.clear();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ]),
    );
  }
}
