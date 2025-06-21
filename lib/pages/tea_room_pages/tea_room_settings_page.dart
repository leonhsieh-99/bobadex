import 'package:bobadex/pages/tea_room_pages/settings_pages/manage_members_page.dart';
import 'package:bobadex/pages/tea_room_pages/settings_pages/manage_room_page.dart';
import 'package:flutter/material.dart';

class TeaRoomSettingsPage extends StatefulWidget {
  final String roomId;
  const TeaRoomSettingsPage({super.key, required this.roomId});

  @override
  State<TeaRoomSettingsPage> createState() => _TeaRoomSettingsPageState();
}

class _TeaRoomSettingsPageState extends State<TeaRoomSettingsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tea Room Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Manage Room'),
              trailing: Icon(Icons.chevron_right),
              leading: Icon(Icons.room),
              subtitle: const Text('Manage room settings and fields'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ManageRoomPage(roomId: widget.roomId))
              ),
            ),
            ListTile(
              title: const Text('Manage Members'),
              trailing: Icon(Icons.chevron_right),
              leading: Icon(Icons.people),
              subtitle: const Text('Remove Members or change room owner'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ManageMembersPage(roomId: widget.roomId))
              ),
            ),
          ],
        ),
      )
    );
  }
}