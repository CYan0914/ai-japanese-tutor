/// Kana character model — 46 hiragana / 46 katakana.
class Kana {
  final String character;
  final String romaji;
  final KanaType type;
  final int row;      // 0-9 (あ行〜わ行)
  final int column;   // 0-4 (a i u e o)
  final bool isGap;   // y-row gaps: yi, ye; w-row gaps: wi, wu, we

  const Kana({
    required this.character,
    required this.romaji,
    required this.type,
    required this.row,
    required this.column,
    this.isGap = false,
  });

  /// KanaTile uses this: show romaji label above, character below.
  String get pronunciation => romaji;
}

enum KanaType { hiragana, katakana }

/// Static kana database — 46 characters each.
class KanaData {
  KanaData._();

  /// Build a 5-column grid (gojuuon table). Row 0 header, rows 1+ data.
  /// gap cells (yi/ye/wi/wu/we) are included with isGap=true.
  static List<List<Kana>> buildGrid(KanaType type) {
    const rows = [
      // romaji prefixes per row
      ['a', 'i', 'u', 'e', 'o'],        // 0: vowels
      ['ka', 'ki', 'ku', 'ke', 'ko'],    // 1
      ['sa', 'shi', 'su', 'se', 'so'],   // 2
      ['ta', 'chi', 'tsu', 'te', 'to'],  // 3
      ['na', 'ni', 'nu', 'ne', 'no'],    // 4
      ['ha', 'hi', 'fu', 'he', 'ho'],    // 5
      ['ma', 'mi', 'mu', 'me', 'mo'],    // 6
      ['ya', null, 'yu', null, 'yo'],    // 7
      ['ra', 'ri', 'ru', 're', 'ro'],    // 8
      ['wa', null, null, null, 'wo'],    // 9
    ];

    const hiragana = [
      ['あ', 'い', 'う', 'え', 'お'],
      ['か', 'き', 'く', 'け', 'こ'],
      ['さ', 'し', 'す', 'せ', 'そ'],
      ['た', 'ち', 'つ', 'て', 'と'],
      ['な', 'に', 'ぬ', 'ね', 'の'],
      ['は', 'ひ', 'ふ', 'へ', 'ほ'],
      ['ま', 'み', 'む', 'め', 'も'],
      ['や', '',  'ゆ', '',  'よ'],
      ['ら', 'り', 'る', 'れ', 'ろ'],
      ['わ', '',  '',   '',  'を'],
    ];

    const katakana = [
      ['ア', 'イ', 'ウ', 'エ', 'オ'],
      ['カ', 'キ', 'ク', 'ケ', 'コ'],
      ['サ', 'シ', 'ス', 'セ', 'ソ'],
      ['タ', 'チ', 'ツ', 'テ', 'ト'],
      ['ナ', 'ニ', 'ヌ', 'ネ', 'ノ'],
      ['ハ', 'ヒ', 'フ', 'ヘ', 'ホ'],
      ['マ', 'ミ', 'ム', 'メ', 'モ'],
      ['ヤ', '',  'ユ', '',  'ヨ'],
      ['ラ', 'リ', 'ル', 'レ', 'ロ'],
      ['ワ', '',  '',   '',  'ヲ'],
    ];

    final chars = type == KanaType.hiragana ? hiragana : katakana;
    final grid = <List<Kana>>[];

    for (var r = 0; r < rows.length; r++) {
      final row = <Kana>[];
      for (var c = 0; c < 5; c++) {
        final romaji = rows[r][c];
        final char = chars[r][c];
        final isGap = romaji == null;
        row.add(Kana(
          character: char.isNotEmpty ? char : '',
          romaji: romaji ?? '',
          type: type,
          row: r,
          column: c,
          isGap: isGap,
        ));
      }
      grid.add(row);
    }

    return grid;
  }

  /// All 46 non-gap characters as a flat list.
  static List<Kana> all(KanaType type) {
    return buildGrid(type)
        .expand((row) => row)
        .where((k) => !k.isGap)
        .toList();
  }

  /// The standalone ん / ン.
  static Kana n(KanaType type) => Kana(
    character: type == KanaType.hiragana ? 'ん' : 'ン',
    romaji: 'n',
    type: type,
    row: 10,
    column: 0,
  );
}
