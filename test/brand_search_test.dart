import 'package:bobadex/brand/brand_search.dart';
import 'package:bobadex/models/brand.dart';
import 'package:flutter_test/flutter_test.dart';

Brand _brand({
  required String slug,
  required String display,
  required List<BrandPlace> places,
  int? locationCount,
}) {
  return Brand(
    slug: slug,
    display: display,
    places: places,
    locationCount: locationCount,
  );
}

const _sanDiego = BrandPlace(
  city: 'San Diego',
  state: 'CA',
  latitude: 32.7,
  longitude: -117.1,
);
const _redwood = BrandPlace(
  city: 'Redwood City',
  state: 'CA',
  latitude: 37.5,
  longitude: -122.2,
);
const _burbank = BrandPlace(
  city: 'Burbank',
  state: 'CA',
  latitude: 34.2,
  longitude: -118.3,
);
const _sacramento = BrandPlace(
  city: 'Sacramento',
  state: 'CA',
  latitude: 38.6,
  longitude: -121.4,
);
const _enterprise = BrandPlace(city: 'Enterprise', state: 'NV');
const _roseville = BrandPlace(city: 'Roseville', state: 'CA');
const _auburn = BrandPlace(city: 'North Auburn', state: 'CA');

void main() {
  test('place lines follow footprint size', () {
    final single = _brand(
      slug: 'sd',
      display: 'Bobalicious',
      places: const [_sanDiego],
    );
    final two = _brand(
      slug: 'loca',
      display: 'Boba Loca',
      places: const [_burbank, _sacramento],
    );
    final many = _brand(
      slug: 'sweet',
      display: 'Sweetea',
      places: const [_roseville, _auburn, _enterprise],
      locationCount: 4,
    );

    expect(brandPlaceLine(single, 'bobalicious'), 'San Diego, CA');
    expect(brandPlaceLine(two, 'boba loca'), 'Burbank · Sacramento, CA');
    expect(brandPlaceLine(many, 'sweetea'), 'Roseville, CA · 4 locations');
  });

  test('a city in the query leads that row', () {
    final brand = _brand(
      slug: 'loca-2',
      display: 'Boba Loca',
      places: const [_burbank, _sacramento],
    );
    expect(
      brandPlaceLine(brand, 'boba loca sacramento'),
      'Sacramento, CA · also Burbank',
    );
  });

  test('same-name rows lead with cities the other row does not use', () {
    final results = searchBrands([
      _brand(
        slug: 'chain',
        display: 'Sweetea',
        places: const [_enterprise, _roseville],
      ),
      _brand(slug: 'shop', display: 'Sweetea', places: const [_enterprise]),
    ], 'sweetea');

    expect(results.map((result) => result.placeLine).toList(), [
      'Roseville, CA · Enterprise, NV',
      'Enterprise, NV',
    ]);
  });

  test('name plus city keeps the matching shop and orders by distance', () {
    final results = searchBrands(
      [
        _brand(slug: 'rw', display: 'Bobalicious', places: const [_redwood]),
        _brand(slug: 'sd', display: 'Bobalicious', places: const [_sanDiego]),
      ],
      'bobalicious',
      latitude: 32.8,
      longitude: -117.2,
    );

    expect(results.map((result) => result.brand.slug).toList(), ['sd', 'rw']);
    expect(results.map((result) => result.placeLine).toList(), [
      'San Diego, CA',
      'Redwood City, CA',
    ]);

    final typed = searchBrands([
      _brand(slug: 'rw', display: 'Bobalicious', places: const [_redwood]),
      _brand(slug: 'sd', display: 'Bobalicious', places: const [_sanDiego]),
    ], 'bobalicious san diego');
    expect(typed.map((result) => result.brand.slug).toList(), ['sd']);
  });
}
