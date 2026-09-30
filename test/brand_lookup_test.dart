import 'package:bobadex/models/brand.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:flutter_test/flutter_test.dart';

Brand _brand(String slug) => Brand(slug: slug, display: slug);

void main() {
  test('brand lookup is by slug', () {
    final state = BrandState()
      ..addBrand(_brand('gong-cha'))
      ..addBrand(_brand('sharetea'));

    expect(state.getBrand('sharetea')?.display, 'sharetea');
    expect(state.getBrand('missing'), isNull);
    expect(state.getName('gong-cha'), 'gong-cha');

    state.reset();
    expect(state.getBrand('gong-cha'), isNull);
    expect(state.getName('gong-cha'), 'gong-cha');
  });

  test('place summaries attach by slug', () {
    final brands = [_brand('gong-cha'), _brand('sharetea')];
    final attached = withPlaceSummaries(brands, [
      {
        'brand_slug': 'sharetea',
        'location_count': 12,
        'places': [
          {'city': 'San Jose', 'state': 'California', 'count': 4},
        ],
      },
    ]);

    expect(attached[0].locationCount, 0);
    expect(attached[1].locationCount, 12);
    expect(attached[1].places.single.city, 'San Jose');
    expect(identical(attached[0], brands[0]), isTrue);
  });
}
