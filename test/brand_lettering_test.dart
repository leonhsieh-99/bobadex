import 'package:bobadex/helpers/brand_lettering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brand lettering is deterministic initials from the name', () {
    expect(brandLettering('Gong Cha'), 'GC');
    expect(brandLettering('Sharetea'), 'SH');
    expect(brandLettering('The Alley'), 'AL');
    expect(brandLettering('Kung Fu Tea'), 'KF');
    expect(brandLettering('Boba Guys'), 'BG');
    expect(brandLettering(''), '?');
    expect(brandLettering('Gong Cha'), brandLettering('Gong Cha'));
  });

  test('brand lettering seed is stable for a slug', () {
    expect(brandLetteringSeed('gong-cha'), brandLetteringSeed('gong-cha'));
    expect(brandLetteringSeed('gong-cha'), isNot(brandLetteringSeed('sharetea')));
  });
}
