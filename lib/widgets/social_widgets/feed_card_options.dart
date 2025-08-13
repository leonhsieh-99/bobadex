import 'package:flutter/widgets.dart';

enum FeedCardVariant { friends, userProfile, brand }

class FeedCardOptions {
  final bool showAvatar;
  final bool showUsername;
  final bool showVerbInline;   // inline “added a shop” next to title
  final bool showVerbPill;     // small pill above content (user profile)
  final bool showBrandLink;    // title clickable to brand page (shop_add)
  final EdgeInsets padding;

  const FeedCardOptions({
    required this.showAvatar,
    required this.showUsername,
    required this.showVerbInline,
    required this.showVerbPill,
    required this.showBrandLink,
    required this.padding,
  });

  factory FeedCardOptions.forVariant(FeedCardVariant v) {
    switch (v) {
      case FeedCardVariant.friends:
        return const FeedCardOptions(
          showAvatar: true,
          showUsername: true,
          showVerbInline: true,
          showVerbPill: false,
          showBrandLink: true,
          padding: EdgeInsets.all(14),
        );
      case FeedCardVariant.userProfile:
        return const FeedCardOptions(
          showAvatar: false,
          showUsername: false,
          showVerbInline: false,
          showVerbPill: true,
          showBrandLink: true,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );
      case FeedCardVariant.brand:
        return const FeedCardOptions(
          showAvatar: true,
          showUsername: true,
          showVerbInline: false,
          showVerbPill: false,
          showBrandLink: false,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );
    }
  }
}