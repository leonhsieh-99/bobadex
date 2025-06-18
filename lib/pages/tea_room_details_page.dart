import 'package:bobadex/state/tea_room_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TeaRoomDetailsPage extends StatefulWidget {
  final String roomId;
  const TeaRoomDetailsPage({
    super.key,
    required this.roomId,
  });

  @override
  State<TeaRoomDetailsPage> createState() => _TeaRoomDetailsPageState();
}

class _TeaRoomDetailsPageState extends State<TeaRoomDetailsPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final teaRoomState = context.read<TeaRoomState>();
    await teaRoomState.loadShops(widget.roomId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final teaRoomState = context.watch<TeaRoomState>();
    final teaRoom = teaRoomState.getTeaRoom(widget.roomId);
    final members = teaRoomState.getMembers(widget.roomId) ?? [];
    final shops = teaRoomState.getShops(widget.roomId) ?? [];

    return Scaffold(
      body: _loading
        ? Center(child: CircularProgressIndicator())
        : CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(teaRoom.name),
                background: _buildHeroHeader(teaRoom),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildMembersRow(members),
            ),
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final shop = shops[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(shop.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Avg rating: ${shop.avgRating.toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: shops.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildHeroHeader(teaRoom) {
    // You can customize this as you wish
    return Container(
      color: Colors.deepPurple[100],
      child: Center(child: Text(teaRoom?.description ?? '', style: TextStyle(fontSize: 18))),
    );
  }

  Widget _buildMembersRow(List members) {
    if (members.isEmpty) return SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: members.take(8).map<Widget>((user) {
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: CircleAvatar(
              radius: 16,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: user.thumbUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    width: 32, height: 32,
                    color: Colors.grey[200],
                  ),
                  errorWidget: (context, _, __) => Icon(Icons.person, size: 18, color: Colors.grey),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
