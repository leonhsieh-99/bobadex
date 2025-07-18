import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ThumbPic extends StatelessWidget {
  final String? url;
  final double size;
  final VoidCallback? onTap;

  const ThumbPic({
    required this.url,
    this.size = 40,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: (url != null && url!.isNotEmpty)
        ? CachedNetworkImage(
          imageUrl: url!,
          imageBuilder: (context, imageProvider) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover, // Ensures the image fills the circle
              ),
            ),
          ),
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
            child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
            child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
          ),
        )
      : Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey,
          ),
          child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
        )
    );
  }
}
