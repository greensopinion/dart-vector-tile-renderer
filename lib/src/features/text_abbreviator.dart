TextAbbreviator _instance = TextAbbreviator._();

class TextAbbreviator {
  final Map<String, String> _wordReplacements = {
    'Alley': 'Aly',
    'Anex': 'Anx',
    'Arcade': 'Arc',
    'Avenue': 'Ave',
    'Bayou': 'Byu',
    'Bluff': 'Blf',
    'Bluffs': 'Blfs',
    'Boulevard': 'Blvd',
    'Branch': 'Br',
    'Brook': 'Brk',
    'Brooks': 'Brks',
    'Bypass': 'Byp',
    'Camp': 'Cp',
    'Canyon': 'Cyn',
    'Causeway': 'Cswy',
    'Center': 'Ctr',
    'Centre': 'Ctr',
    'Circle': 'Cir',
    'Court': 'Ct',
    'Creek': 'Crk',
    'Crescent': 'Cres',
    'Crossing': 'Xing',
    'Dale': 'Dl',
    'Divide': 'Dv',
    'Drive': 'Dr',
    'Estate': 'Est',
    'Estates': 'Ests',
    'Expressway': 'Expy',
    'Fort': 'Ft',
    'Freeway': 'Fwy',
    'Heights': 'Hts',
    'Highway': 'Hwy',
    'Island': 'Is',
    'Junction': 'Jct',
    'Lake': 'Lk',
    'Lane': 'Ln',
    'Mountain': 'Mtn',
    'Parkway': 'Pkwy',
    'Place': 'Pl',
    'Point': 'Pt',
    'Street': 'St',
    'Square': 'Sq',
    'Station': 'Stn',
    'Road': 'Rd',
    'View': 'Vw',
    'Way': 'Wy',
  };
  factory TextAbbreviator() => _instance;
  TextAbbreviator._();

  String abbreviate(String text) {
    final parts = text.split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return text;
    }
    final last = parts.last;
    parts.removeLast();
    parts.add(_replace(last));
    return parts.join(' ');
  }

  String _replace(String word) {
    return _wordReplacements[word] ?? word;
  }
}
