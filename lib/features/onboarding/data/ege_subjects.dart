/// Полный список предметов ЕГЭ, доступных для выбора в онбординге.
///
/// 12 пунктов: профильная и базовая математика идут отдельными строчками,
/// чтобы пользователь сразу понимал, что выбирает.
class EgeSubject {
  const EgeSubject({
    required this.id,
    required this.title,
    required this.iconAsset,
  });

  /// Стабильный идентификатор для хранения (не зависит от перевода UI).
  final String id;
  final String title;

  /// Путь к локальному PNG-ассету (Twemoji 72×72) в `assets/subjects/`.
  /// Лежит в репозитории и собирается в бандл — работает офлайн.
  final String iconAsset;
}

// Все 12 иконок — Twemoji 72×72, скачаны в `assets/subjects/`. Чтобы
// добавить новую — положи PNG туда же и сошлись через `assets/subjects/<code>.png`.
const egeSubjects = <EgeSubject>[
  EgeSubject(
    id: 'rus',
    title: 'Русский язык',
    // 📕 closed book
    iconAsset: 'assets/subjects/1f4d5.png',
  ),
  EgeSubject(
    id: 'math_prof',
    title: 'Математика (проф.)',
    // 📐 triangular ruler
    iconAsset: 'assets/subjects/1f4d0.png',
  ),
  EgeSubject(
    id: 'math_base',
    title: 'Математика (база)',
    // 🧮 abacus
    iconAsset: 'assets/subjects/1f9ee.png',
  ),
  EgeSubject(
    id: 'physics',
    title: 'Физика',
    // ⚛ atom symbol
    iconAsset: 'assets/subjects/269b.png',
  ),
  EgeSubject(
    id: 'chemistry',
    title: 'Химия',
    // 🧪 test tube
    iconAsset: 'assets/subjects/1f9ea.png',
  ),
  EgeSubject(
    id: 'biology',
    title: 'Биология',
    // 🧬 dna
    iconAsset: 'assets/subjects/1f9ec.png',
  ),
  EgeSubject(
    id: 'history',
    title: 'История',
    // 🏛 classical building
    iconAsset: 'assets/subjects/1f3db.png',
  ),
  EgeSubject(
    id: 'social',
    title: 'Обществознание',
    // ⚖ scales
    iconAsset: 'assets/subjects/2696.png',
  ),
  EgeSubject(
    id: 'literature',
    title: 'Литература',
    // 📖 open book
    iconAsset: 'assets/subjects/1f4d6.png',
  ),
  EgeSubject(
    id: 'geography',
    title: 'География',
    // 🌍 globe (Europe-Africa)
    iconAsset: 'assets/subjects/1f30d.png',
  ),
  EgeSubject(
    id: 'informatics',
    title: 'Информатика',
    // 💻 laptop
    iconAsset: 'assets/subjects/1f4bb.png',
  ),
  EgeSubject(
    id: 'english',
    title: 'Английский язык',
    // 🇬🇧 flag UK (composite codepoint)
    iconAsset: 'assets/subjects/1f1ec-1f1e7.png',
  ),
];

const egeSubjectsMin = 3;
const egeSubjectsMax = 5;
