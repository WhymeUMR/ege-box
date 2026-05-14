/// Полный список предметов ЕГЭ, доступных для выбора в онбординге.
///
/// 12 пунктов: профильная и базовая математика идут отдельными строчками,
/// чтобы пользователь сразу понимал, что выбирает.
class EgeSubject {
  const EgeSubject({
    required this.id,
    required this.title,
    required this.iconUrl,
    this.emoji,
  });

  /// Стабильный идентификатор для хранения (не зависит от перевода UI).
  final String id;
  final String title;

  /// PNG-иконка из CDN icons8 (color, 96px). Подгружается сетью с
  /// фолбэком на [emoji], если интернет недоступен.
  final String iconUrl;
  final String? emoji;
}

// Единый CDN для всех иконок — OpenMoji (color, 72×72 PNG). Все эмодзи
// гарантированно отдают валидный PNG, поэтому одинаково стабильно
// работают и проф. математика, и история, и т.д.
const egeSubjects = <EgeSubject>[
  EgeSubject(
    id: 'rus',
    title: 'Русский язык',
    // 📕 closed book
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f4d5.png',
    emoji: '📕',
  ),
  EgeSubject(
    id: 'math_prof',
    title: 'Математика (проф.)',
    // 📐 triangular ruler
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f4d0.png',
    emoji: '📐',
  ),
  EgeSubject(
    id: 'math_base',
    title: 'Математика (база)',
    // 🧮 abacus
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f9ee.png',
    emoji: '🧮',
  ),
  EgeSubject(
    id: 'physics',
    title: 'Физика',
    // ⚛ atom symbol
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/269b.png',
    emoji: '⚛️',
  ),
  EgeSubject(
    id: 'chemistry',
    title: 'Химия',
    // 🧪 test tube
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f9ea.png',
    emoji: '🧪',
  ),
  EgeSubject(
    id: 'biology',
    title: 'Биология',
    // 🧬 dna
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f9ec.png',
    emoji: '🧬',
  ),
  EgeSubject(
    id: 'history',
    title: 'История',
    // 🏛 classical building
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f3db.png',
    emoji: '🏛️',
  ),
  EgeSubject(
    id: 'social',
    title: 'Обществознание',
    // ⚖ scales
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/2696.png',
    emoji: '⚖️',
  ),
  EgeSubject(
    id: 'literature',
    title: 'Литература',
    // 📖 open book
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f4d6.png',
    emoji: '📖',
  ),
  EgeSubject(
    id: 'geography',
    title: 'География',
    // 🌍 globe (Europe-Africa)
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f30d.png',
    emoji: '🌍',
  ),
  EgeSubject(
    id: 'informatics',
    title: 'Информатика',
    // 💻 laptop
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f4bb.png',
    emoji: '💻',
  ),
  EgeSubject(
    id: 'english',
    title: 'Английский язык',
    // 🇬🇧 flag UK (composite codepoint)
    iconUrl: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f1ec-1f1e7.png',
    emoji: '🇬🇧',
  ),
];

const egeSubjectsMin = 3;
const egeSubjectsMax = 5;
