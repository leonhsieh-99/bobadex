import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TeaRoomBanner extends StatelessWidget {
  final String name;
  final String? description;
  final Color accentColor;
  final List<String> memberAvatars;
  final void Function()? onTap;

  const TeaRoomBanner({
    required this.name,
    this.description,
    this.accentColor = const Color(0xFFE1D6F9),
    this.memberAvatars = const [],
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              // Pearl avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: accentColor,
                child: Icon(Icons.emoji_food_beverage, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (description != null && description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Avatars Row
                    Row(
                      children: memberAvatars
                          .take(5) // show up to 5
                          .map((url) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  placeholder: (context, _) => Container(
                                    width: 24, height: 24,
                                    color: Colors.grey[200],
                                  ),
                                  errorWidget: (context, _, __) => Icon(Icons.person, size: 18, color: Colors.grey),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
