import 'package:bobadex/ui/components/entry_tile.dart';
import 'package:bobadex/models/shop.dart';
import 'package:flutter/material.dart';

class ShopGridTile extends StatelessWidget {
  final Shop shop;
  final int columns;
  final bool useIcons;
  final VoidCallback onTap;

  const ShopGridTile({
    super.key,
    required this.shop,
    required this.columns,
    required this.useIcons,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EntryTile(
      shop: shop,
      columns: columns,
      useIcons: useIcons,
      onTap: onTap,
    );
  }
}
