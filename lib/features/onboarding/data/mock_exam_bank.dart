class MockExamTask {
  const MockExamTask({
    required this.id,
    required this.source,
    required this.prompt,
    required this.correctAnswer,
  });

  final String id;
  final String source;
  final String prompt;
  final String correctAnswer;
}

const mockExamBankBySubject = <String, List<MockExamTask>>{
  'rus': [
    MockExamTask(
      id: 'rus_1',
      source: 'Формат ЕГЭ: орфоэпия',
      prompt:
          'Укажите слово, в котором верно выделена буква, обозначающая ударный гласный: звонИт, тОрты, крАны, свЁкла.',
      correctAnswer: 'звонит',
    ),
    MockExamTask(
      id: 'rus_2',
      source: 'Формат ЕГЭ: лексика',
      prompt: 'Подберите синоним к слову «лаконичный».',
      correctAnswer: 'краткий',
    ),
    MockExamTask(
      id: 'rus_3',
      source: 'Формат ЕГЭ: пунктуация',
      prompt:
          'Сколько запятых нужно поставить в предложении: «Когда стемнело мы вернулись домой»?',
      correctAnswer: '1',
    ),
  ],
  'math_prof': [
    MockExamTask(
      id: 'math_prof_1',
      source: 'Формат ЕГЭ: профиль, алгебра',
      prompt: 'Решите уравнение: 2x + 7 = 19. Введите x.',
      correctAnswer: '6',
    ),
    MockExamTask(
      id: 'math_prof_2',
      source: 'Формат ЕГЭ: профиль, проценты',
      prompt: 'Цена товара 5000 рублей. Скидка 20%. Укажите новую цену.',
      correctAnswer: '4000',
    ),
    MockExamTask(
      id: 'math_prof_3',
      source: 'Формат ЕГЭ: профиль, геометрия',
      prompt: 'В прямоугольном треугольнике катеты 3 и 4. Укажите гипотенузу.',
      correctAnswer: '5',
    ),
  ],
  'math_base': [
    MockExamTask(
      id: 'math_base_1',
      source: 'Формат ЕГЭ: база, арифметика',
      prompt: 'Вычислите: 48 : 6 + 7.',
      correctAnswer: '15',
    ),
    MockExamTask(
      id: 'math_base_2',
      source: 'Формат ЕГЭ: база, числа',
      prompt: 'На сколько 92 больше, чем 57?',
      correctAnswer: '35',
    ),
    MockExamTask(
      id: 'math_base_3',
      source: 'Формат ЕГЭ: база, дроби',
      prompt: 'Вычислите: 0.5 + 0.25.',
      correctAnswer: '0.75',
    ),
  ],
  'physics': [
    MockExamTask(
      id: 'physics_1',
      source: 'Формат ЕГЭ: механика',
      prompt:
          'Тело движется равномерно со скоростью 10 м/с в течение 3 с. Укажите путь в метрах.',
      correctAnswer: '30',
    ),
    MockExamTask(
      id: 'physics_2',
      source: 'Формат ЕГЭ: электричество',
      prompt: 'По закону Ома найдите силу тока при U=12 В и R=4 Ом.',
      correctAnswer: '3',
    ),
    MockExamTask(
      id: 'physics_3',
      source: 'Формат ЕГЭ: работа',
      prompt: 'Работа силы 100 Дж, путь 5 м. Найдите силу в Ньютонах.',
      correctAnswer: '20',
    ),
  ],
  'chemistry': [
    MockExamTask(
      id: 'chem_1',
      source: 'Формат ЕГЭ: периодическая система',
      prompt: 'Укажите химический символ кислорода.',
      correctAnswer: 'o',
    ),
    MockExamTask(
      id: 'chem_2',
      source: 'Формат ЕГЭ: молярная масса',
      prompt: 'Молярная масса воды H2O (г/моль).',
      correctAnswer: '18',
    ),
    MockExamTask(
      id: 'chem_3',
      source: 'Формат ЕГЭ: валентность',
      prompt: 'В соединении CO2 валентность кислорода равна:',
      correctAnswer: '2',
    ),
  ],
  'biology': [
    MockExamTask(
      id: 'bio_1',
      source: 'Формат ЕГЭ: клетка',
      prompt: 'Где хранится наследственная информация клетки? (одно слово)',
      correctAnswer: 'ядро',
    ),
    MockExamTask(
      id: 'bio_2',
      source: 'Формат ЕГЭ: генетика',
      prompt: 'Сколько хромосом в соматических клетках человека?',
      correctAnswer: '46',
    ),
    MockExamTask(
      id: 'bio_3',
      source: 'Формат ЕГЭ: ботаника',
      prompt: 'Процесс образования органических веществ на свету:',
      correctAnswer: 'фотосинтез',
    ),
  ],
  'history': [
    MockExamTask(
      id: 'hist_1',
      source: 'Формат ЕГЭ: даты',
      prompt: 'Укажите год начала Великой Отечественной войны.',
      correctAnswer: '1941',
    ),
    MockExamTask(
      id: 'hist_2',
      source: 'Формат ЕГЭ: даты',
      prompt: 'Укажите год отмены крепостного права в России.',
      correctAnswer: '1861',
    ),
    MockExamTask(
      id: 'hist_3',
      source: 'Формат ЕГЭ: личности',
      prompt: 'Первый российский император (фамилия или имя).',
      correctAnswer: 'петр i',
    ),
  ],
  'social': [
    MockExamTask(
      id: 'soc_1',
      source: 'Формат ЕГЭ: экономика',
      prompt:
          'Как называется обязательный платеж государству с доходов и имущества?',
      correctAnswer: 'налог',
    ),
    MockExamTask(
      id: 'soc_2',
      source: 'Формат ЕГЭ: право',
      prompt: 'Основной закон Российской Федерации:',
      correctAnswer: 'конституция',
    ),
    MockExamTask(
      id: 'soc_3',
      source: 'Формат ЕГЭ: политика',
      prompt: 'Форма правления в РФ:',
      correctAnswer: 'республика',
    ),
  ],
  'literature': [
    MockExamTask(
      id: 'lit_1',
      source: 'Формат ЕГЭ: авторы',
      prompt: 'Кто написал роман «Война и мир»? (фамилия)',
      correctAnswer: 'толстой',
    ),
    MockExamTask(
      id: 'lit_2',
      source: 'Формат ЕГЭ: жанры',
      prompt: '«Евгений Онегин» по жанру — роман в ... (одно слово).',
      correctAnswer: 'стихах',
    ),
    MockExamTask(
      id: 'lit_3',
      source: 'Формат ЕГЭ: термины',
      prompt: 'Как называется художественное преувеличение? (термин)',
      correctAnswer: 'гипербола',
    ),
  ],
  'geography': [
    MockExamTask(
      id: 'geo_1',
      source: 'Формат ЕГЭ: карта',
      prompt: 'Столица России:',
      correctAnswer: 'москва',
    ),
    MockExamTask(
      id: 'geo_2',
      source: 'Формат ЕГЭ: океаны',
      prompt: 'Самый большой океан Земли:',
      correctAnswer: 'тихий',
    ),
    MockExamTask(
      id: 'geo_3',
      source: 'Формат ЕГЭ: численность',
      prompt: 'Сколько материков на Земле в школьной географии?',
      correctAnswer: '6',
    ),
  ],
  'informatics': [
    MockExamTask(
      id: 'inf_1',
      source: 'Формат ЕГЭ: системы счисления',
      prompt: 'Переведите число 10 из десятичной системы в двоичную.',
      correctAnswer: '1010',
    ),
    MockExamTask(
      id: 'inf_2',
      source: 'Формат ЕГЭ: кодирование',
      prompt: 'Сколько бит в 1 байте?',
      correctAnswer: '8',
    ),
    MockExamTask(
      id: 'inf_3',
      source: 'Формат ЕГЭ: логика',
      prompt: 'Значение выражения: ИСТИНА И ЛОЖЬ.',
      correctAnswer: 'ложь',
    ),
  ],
  'english': [
    MockExamTask(
      id: 'eng_1',
      source: 'Формат ЕГЭ: grammar',
      prompt: 'Choose correct form: She ... to school every day.',
      correctAnswer: 'goes',
    ),
    MockExamTask(
      id: 'eng_2',
      source: 'Формат ЕГЭ: vocabulary',
      prompt: 'Translate to English: «книга».',
      correctAnswer: 'book',
    ),
    MockExamTask(
      id: 'eng_3',
      source: 'Формат ЕГЭ: tenses',
      prompt: 'Past form of verb "write":',
      correctAnswer: 'wrote',
    ),
  ],
};
