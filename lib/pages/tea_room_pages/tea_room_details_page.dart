import 'package:bobadex/pages/tea_room_pages/add_tea_room_members_page.dart';
import 'package:bobadex/pages/tea_room_pages/tea_room_settings_page.dart';
import 'package:bobadex/state/tea_room_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final teaRoomState = context.read<TeaRoomState>();
    await teaRoomState.loadShops(widget.roomId);
    _isOwner = teaRoomState.getTeaRoom(widget.roomId).ownerId == Supabase.instance.client.auth.currentUser!.id;
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final teaRoomState = context.watch<TeaRoomState>();
    final teaRoom = teaRoomState.getTeaRoom(widget.roomId);
    final members = teaRoomState.getMembers(widget.roomId) ?? [];
    final shops = teaRoomState.getShops(widget.roomId) ?? [];

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_isOwner)
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TeaRoomSettingsPage(roomId: widget.roomId)
            )),
            icon: Icon(Icons.settings)
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
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
            if (_loading) {
              return _buildLoadingPearl();
            } else if (i < shops.length) {
              final shop = shops[i];
              return _buildShopPearl(shop);
            } else {
              return SizedBox.shrink(); // Never render past the real data!
            }
                },
                childCount: _loading ? 8 : shops.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(teaRoom) {
    return Container(
      color: Colors.deepPurple[100],
      child: Center(child: Text(teaRoom?.description ?? '', style: TextStyle(fontSize: 18))),
    );
  }

  Widget _buildMembersRow(List members) {
    if (members.isEmpty) return SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Row(
      children: [
        ...members.take(8).map<Widget>((user) {
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: CircleAvatar(
              radius: 16,
              child: ClipOval(
                child: (user.thumbUrl ?? '').trim().isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: user.thumbUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => Container(
                      width: 32, height: 32,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, _, __) => Icon(Icons.person, size: 18, color: Colors.grey),
                  )
                  : Icon(Icons.person)
              ),
            ),
          );
        }),
        Spacer(), // this pushes the button to the right
        IconButton(
          icon: Icon(Icons.person_add_alt_1),
          color: Theme.of(context).primaryColor,
          tooltip: 'Invite Friends',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddTeaRoomMembersPage(roomId: widget.roomId))
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildLoadingPearl() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Grayed out circle (pearl)
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 10),
        // Grayed-out text bars
        Container(
          height: 16,
          width: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 12,
          width: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildShopPearl(shop) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            shape: BoxShape.circle,
          ),
          child: (shop.iconPath != null && shop.iconPath!.trim().isNotEmpty)
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: shop.iconPath!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, _, __) => Icon(Icons.store, size: 30, color: Colors.grey),
                ),
              )
            : Icon(Icons.emoji_food_beverage, size: 30, color: Colors.deepPurple.shade200),
        ),
        const SizedBox(height: 10),
        Text(
          shop.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 5),
        Text(
          'Avg: ${shop.avgRating.toStringAsFixed(1)}',
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 5),
        Text(
          'Ratings: ${shop.memberRatings.length.toString()}',
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
