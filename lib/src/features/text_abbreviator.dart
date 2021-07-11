TextAbbreviator _instance = TextAbbreviator._();

class TextAbbreviator {
  final Map<String, String> _wordReplacements = {
    'Avenue': 'Ave',
    'Street': 'St',
    'Drive': 'Dr',
    'Boulevard': 'Blvd',
    'Crescent': 'Cres',
    'Place': 'Pl',
    'Road': 'Rd',
    'Square': 'Sq',
    'Highway': 'Hwy'
  };
  factory TextAbbreviator() => _instance;
  TextAbbreviator._();

  String abbreviate(String text) {
    final parts = text.split(RegExp(r'\s+'));
    return parts.map((e) => _replace(e)).join(' ');
  }

  String _replace(String word) {
    return _wordReplacements[word] ?? word;
  }
}
