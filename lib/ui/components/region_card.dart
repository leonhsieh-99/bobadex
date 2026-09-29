import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/boba_progress_bar.dart';
import 'package:bobadex/ui/components/region_seal.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

class RegionCard extends StatelessWidget {
  const RegionCard({super.key, required this.county, required this.onTap});

  final CountySummary county;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final fraction = county.eligibleTotal == 0
        ? 0.0
        : county.discoveredTotal / county.eligibleTotal;
    return BobaCard(
      onTap: onTap,
      accentSpine: BrandMark.accentFor(county.countyPlaceId),
      child: Row(
        children: [
          RegionSeal(name: county.countyName, complete: county.isComplete),
          const SizedBox(width: BobaSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  county.countyName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  county.isComplete ? 'Complete' : county.stateName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: county.isComplete
                        ? tokens.accentInk
                        : tokens.inkMuted,
                  ),
                ),
                const SizedBox(height: BobaSpace.x2),
                BobaProgressBar(value: fraction),
              ],
            ),
          ),
          const SizedBox(width: BobaSpace.x3),
          Text(
            '${county.discoveredTotal} / ${county.eligibleTotal}',
            style: context.bobaText.numeral(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
