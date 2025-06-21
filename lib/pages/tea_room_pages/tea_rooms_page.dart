import 'package:bobadex/config/constants.dart';
import 'package:bobadex/pages/tea_room_pages/tea_room_details_page.dart';
import 'package:bobadex/state/tea_room_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/add_tea_room_dialog.dart';
import 'package:bobadex/widgets/tea_room_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TeaRoomsPage extends StatefulWidget {
  const TeaRoomsPage({
    super.key,
  });

  @override
  State<TeaRoomsPage> createState() => _TeaRoomsPageState();
}

class _TeaRoomsPageState extends State<TeaRoomsPage> {
  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final teaRoomState = context.watch<TeaRoomState>();
    final user = userState.user;
    final rooms = teaRoomState.all;
    final themeColor = Constants.getThemeColor(user.themeSlug);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tea Rooms'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeColor.shade200,
                  style: BorderStyle.solid,
                  width: 1.0,
                )
              ),
              child: TextButton(
                onPressed: () => {
                  showDialog(
                    context: context,
                    builder: (_) => AddTeaRoomDialog(
                      onSubmit: (teaRoom) async {
                        try {
                          await teaRoomState.add(teaRoom.copyWith(ownerId: user.id), user);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added tea room!'))
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add tea room: $e'))
                          );
                        }
                      }
                    )
                  )
                }, // nav to create room
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Create new Tea Room',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ]
                ),
              )
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: teaRoomState.all.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final members = teaRoomState.getMembers(room.id) ?? [];
                  return TeaRoomBanner(
                    name: room.name,
                    description: room.description,
                    accentColor: themeColor,
                    memberAvatars: members.map((u) => u.thumbUrl).toList(),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TeaRoomDetailsPage(roomId: room.id))
                    )
                  );
                },
              ),
            )
          ],
        )
      )
    );
  }
}