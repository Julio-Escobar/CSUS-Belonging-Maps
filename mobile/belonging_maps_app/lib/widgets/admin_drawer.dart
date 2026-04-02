import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAdmin) {
      return const Drawer(
        child: Center(child: Text("User Menu")),
      );
    }

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              children: const [
                Icon(Icons.admin_panel_settings, size: 50),
                Text("Admin Panel"),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit Maps"),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Add Location"),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Delete Entries"),
          ),
        ],
      ),
    );
  }
}