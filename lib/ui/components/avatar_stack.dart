import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.paths,
    this.size = 24,
    this.maxVisible = 3,
  });

  final List<String?> paths;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = paths.take(maxVisible).toList();
    final overflow = paths.length - visible.length;
    final step = size * 0.7;
    final count = visible.length + (overflow > 0 ? 1 : 0);
    final width = count == 0 ? 0.0 : size + (count - 1) * step;
    final tokens = context.boba;

    return Semantics(
      label: '${paths.length} people',
      child: SizedBox(
        width: width,
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < visible.length; i++)
              Positioned(
                left: i * step,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.surface, width: 2),
                  ),
                  child: ThumbPic(path: visible[i], size: size - 4),
                ),
              ),
            if (overflow > 0)
              Positioned(
                left: visible.length * step,
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.surface, width: 2),
                  ),
                  child: Text(
                    '+$overflow',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
