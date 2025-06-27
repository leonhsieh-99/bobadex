import 'package:bobadex/models/brand.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrandDetailsPage extends StatefulWidget {
  final Brand brand;

  const BrandDetailsPage({super.key, required this.brand});

  @override
  State<BrandDetailsPage> createState() => _BrandDetailsPageState();
}

class _BrandDetailsPageState extends State<BrandDetailsPage> {
  @override
  void initState() {
    fetchStats();
    super.initState();

  }

  Future<List<List<dynamic>>> fetchStats() async {
    return [[],[]];
  }

  @override
  Widget build(BuildContext context) {
    final brandState = context.read<BrandState>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.brand.display)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.brand.thumbUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.brand.display,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          // const SizedBox(height: 8),
          // _buildGlobalRatings(widget.brand),
          // const SizedBox(height: 24),
          // _buildGlobalGallery(widget.brand),
          // const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Widget _buildGlobalRatings(Brand brand) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text('Community Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//       SizedBox(height: 8),
//       Row(
//         children: [
//           Icon(Icons.star, color: Colors.orangeAccent),
//           SizedBox(width: 8),
//           Text('${widget.brand.avgRating.toStringAsFixed(1)} (${brand.totalRatings} ratings)',
//               style: TextStyle(fontSize: 16)),
//         ],
//       ),
//     ],
//   );
// }

// Widget _buildGlobalGallery(Brand brand) {
//   // Replace with global gallery logic
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text('Community Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//       SizedBox(height: 8),
//       SizedBox(
//         height: 100,
//         child: brand.globalGallery.isEmpty
//             ? Center(child: Text('No community photos yet'))
//             : ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: brand.globalGallery.length,
//                 separatorBuilder: (_, __) => SizedBox(width: 8),
//                 itemBuilder: (context, index) {
//                   return ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: CachedNetworkImage(
//                       imageUrl: brand.globalGallery[index],
//                       width: 100,
//                       height: 100,
//                       fit: BoxFit.cover,
//                     ),
//                   );
//                 },
//               ),
//       ),
//     ],
//   );
// }