const locationNameAttributeFields = ['Company_Name', 'Name', 'FACILITY_NAME'];

String cleanLocationAttribute(dynamic value) {
  final text = value?.toString().trim() ?? '';
  final normalized = text.toLowerCase();
  if (normalized.isEmpty || normalized == 'n/a' || normalized == 'null') {
    return '';
  }
  return text;
}

String locationTitleFromAttributes(
  Map<String, dynamic>? attributes, {
  String fallback = 'Unnamed location',
}) {
  for (final field in locationNameAttributeFields) {
    final value = cleanLocationAttribute(attributes?[field]);
    if (value.isNotEmpty) return value;
  }
  return fallback;
}
