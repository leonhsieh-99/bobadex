import 'dart:convert';

/// Authenticated `request-brand` body. Country defaults to the United States.
/// One optional http(s) link is supporting evidence. Address is optional.
class BrandRequestDraft {
  const BrandRequestDraft({
    required this.name,
    required this.city,
    required this.state,
    this.country = 'United States',
    this.address,
    this.sourceUrl,
  });

  final String name;
  final String city;
  final String state;
  final String country;
  final String? address;
  final String? sourceUrl;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'name': name.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'country': country.trim().isEmpty ? 'United States' : country.trim(),
    };
    final street = address?.trim();
    if (street != null && street.isNotEmpty) body['address'] = street;
    final url = sourceUrl?.trim();
    if (url != null && url.isNotEmpty) body['source_url'] = url;
    return body;
  }
}

class BrandRequestHttp {
  const BrandRequestHttp({required this.status, required this.body});

  final int status;
  final Map<String, dynamic> body;
}

/// Shown for every accepted request, including ones that match an old record.
const brandRequestPendingMessage = 'Request submitted for review.';

final _evidenceUrl = RegExp(r'^https?://\S+$', caseSensitive: false);

/// Client checks only. Same-name requests are not duplicates here.
String? validateBrandRequest(BrandRequestDraft draft) {
  final name = draft.name.trim();
  if (name.isEmpty || name.length > 160) {
    return 'Enter a brand name up to 160 characters.';
  }
  if (draft.city.trim().isEmpty || draft.state.trim().isEmpty) {
    return 'Select a city and state.';
  }
  final country = draft.country.trim();
  if (country.isEmpty || country.length > 100) {
    return 'Select a city and state.';
  }
  if (draft.city.trim().length > 100 || draft.state.trim().length > 100) {
    return 'Select a city and state.';
  }
  final street = draft.address?.trim();
  if (street != null && street.length > 300) {
    return 'That address is too long.';
  }
  final url = draft.sourceUrl?.trim();
  if (url != null && url.isNotEmpty && !_evidenceUrl.hasMatch(url)) {
    return 'Use one http or https link.';
  }
  return null;
}

Map<String, dynamic> brandRequestBodyFromUnknown(dynamic raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return {};
}

bool isAcceptedBrandRequest(Map<String, dynamic> body) {
  final stagingId = body['staging_id'];
  return body['status'] == 'pending' &&
      body['outcome'] == 'submitted_for_review' &&
      stagingId is String &&
      stagingId.isNotEmpty;
}

String messageForBrandRequestFailure(BrandRequestHttp response) {
  final raw = response.body['error'] ?? response.body['message'];
  final code = raw is String ? raw.trim() : '';
  if (response.status == 401 ||
      code == 'Unauthorized' ||
      code == 'authentication_required') {
    return 'Please sign in to request a brand.';
  }
  return switch (code) {
    'invalid_brand_name' => 'Enter a brand name up to 160 characters.',
    'invalid_structured_locality' => 'Select a city and state.',
    'invalid_source_url' => 'Use one http or https link.',
    'invalid_storefront_address' => 'That address is too long.',
    _ => 'Could not submit that request. Please try again.',
  };
}

/// Returns null when the request was accepted. Otherwise a user-facing error.
Future<String?> submitBrandRequest({
  required BrandRequestDraft draft,
  required Future<BrandRequestHttp> Function(Map<String, dynamic> body) invoke,
  required bool signedIn,
}) async {
  if (!signedIn) return 'Please sign in to request a brand.';
  final invalid = validateBrandRequest(draft);
  if (invalid != null) return invalid;
  try {
    final response = await invoke(draft.toJson());
    if (response.status >= 200 &&
        response.status < 300 &&
        isAcceptedBrandRequest(response.body)) {
      return null;
    }
    if (response.status >= 200 && response.status < 300) {
      return 'Could not submit that request. Please try again.';
    }
    return messageForBrandRequestFailure(response);
  } catch (_) {
    return 'Could not submit that request. Please try again.';
  }
}
