import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class DialCountry {
  final IsoCode iso;
  final String name;
  const DialCountry(this.iso, this.name);

  String get dialLabel => '+${PhoneNumber(isoCode: iso, nsn: '').countryCode}';
}

/// Common destinations for Bobadex. Parsing still uses libphonenumber metadata.
const kDialCountries = [
  DialCountry(IsoCode.US, 'United States'),
  DialCountry(IsoCode.CA, 'Canada'),
  DialCountry(IsoCode.TW, 'Taiwan'),
  DialCountry(IsoCode.HK, 'Hong Kong'),
  DialCountry(IsoCode.CN, 'China'),
  DialCountry(IsoCode.GB, 'United Kingdom'),
  DialCountry(IsoCode.AU, 'Australia'),
  DialCountry(IsoCode.SG, 'Singapore'),
  DialCountry(IsoCode.MY, 'Malaysia'),
  DialCountry(IsoCode.VN, 'Vietnam'),
  DialCountry(IsoCode.TH, 'Thailand'),
  DialCountry(IsoCode.JP, 'Japan'),
  DialCountry(IsoCode.KR, 'South Korea'),
  DialCountry(IsoCode.PH, 'Philippines'),
  DialCountry(IsoCode.IN, 'India'),
  DialCountry(IsoCode.MX, 'Mexico'),
  DialCountry(IsoCode.DE, 'Germany'),
  DialCountry(IsoCode.FR, 'France'),
];

String? emailToOtpIdentifier(String raw) {
  final email = raw.trim().toLowerCase();
  if (email.length > 254) return null;
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) return null;
  return email;
}

/// Converts user input to E.164 using [phone_numbers_parser]. Does not concatenate dial codes by hand.
String? phoneToE164(String raw, IsoCode country) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  try {
    final parsed = PhoneNumber.parse(
      trimmed,
      callerCountry: country,
    );
    if (!parsed.isValid()) return null;
    return parsed.international;
  } catch (_) {
    return null;
  }
}

bool isOtpCode(String raw) => RegExp(r'^[0-9]{6,8}$').hasMatch(raw.trim());
