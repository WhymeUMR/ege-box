class AppStrings {
  AppStrings._();

  static const appTitle = 'Ege Box';

  // Welcome
  static const welcomeTaglines = <String>[
    'Пора готовиться к экзаменам с лучшим сервисом',
    'Сдай ЕГЭ на максимум вместе с нами',
    'Тысячи задач для уверенной подготовки',
    'Учись эффективно — каждый день ближе к цели',
    'Твой путь к высоким баллам начинается здесь',
  ];
  static const signIn = 'Войти';
  static const signUp = 'Зарегистрироваться';

  // Auth forms
  static const emailHint = 'Почта';
  static const passwordHint = 'Пароль';
  static const nameHint = 'Имя';
  static const passwordRepeatHint = 'Повторите пароль';
  static const signInWithTelegram = 'Войти через Telegram';
  static const forgotPassword = 'Забыли пароль?';
  static const or = 'или';

  // Hero texts
  static const loginTitle = 'С возвращением!';
  static const loginSubtitle = 'Продолжим подготовку к экзаменам';
  static const registerTitle = 'Создаём аккаунт';
  static const registerSubtitle = 'Пара шагов — и ты с нами';
  static const noAccountYet = 'Нет аккаунта? ';
  static const alreadyHaveAccount = 'Уже есть аккаунт? ';

  // Password requirements hint (показываем в подсказке под полем при ошибке).
  static const passwordRequirements =
      'Минимум 8 символов, буква, цифра и спецсимвол';

  // Onboarding
  static const onboardingStepClass = 'Шаг 1 из 3 — Класс';
  static String onboardingClassTitle(String name) =>
      '$name, в каком ты сейчас классе?';
  static const onboardingClassSubtitle =
      'Это нужно, чтобы я понимал, сколько у нас времени до экзамена и какие темы уже пройдены в школе.';
  static const onboardingNext = 'Далее';
  static const onboardingStepSubjects = 'Шаг 2 из 3 — Предметы';
  static const onboardingSubjectsTitle = 'Какие предметы сдаёшь?';
  static const onboardingSubjectsSubtitle =
      'Отметь все предметы, которые сдаёшь (3–5).\nНажми ещё раз, чтобы снять отметку.';
  static String onboardingSubjectsCounter(int selected, int min, int max) =>
      'Выбрано $selected • нужно от $min до $max';
  static const onboardingStepHours = 'Шаг 3 из 3 — Время на подготовку';
  static String onboardingHoursTitle(String name) =>
      '$name, сколько часов в неделю ты готов уделять подготовке?';
  static const onboardingHoursSubtitle =
      'От этого зависит, сколько задач я буду давать в день (в среднем ~17 минут на одну).';
  static const onboardingFinish = 'Готово';
  static const onboardingMockTitle = 'Самое время написать пробник';
  static String onboardingMockBody(String name) =>
      '$name, если хочешь, можешь прямо сейчас написать пробник по одному из выбранных предметов. Это поможет точнее подобрать сложность задач и заодно познакомиться с платформой.';
  static const onboardingMockHint =
      'После каждого пробника ты вернёшься на этот экран с обновлённым баллом и сможешь пройти следующий предмет.';
  static const onboardingMockChoose = 'Выбери предмет для пробника';
  static const onboardingMockStart = 'Приступить';
  static const onboardingMockSkip = 'Пропустить';

  // Forgot password
  static const forgotTitle = 'Забыли пароль?';
  static const forgotSubtitle =
      'Введи почту — отправим ссылку для сброса пароля';
  static const sendResetLink = 'Отправить ссылку';
  static const rememberedPassword = 'Вспомнили пароль? ';
}
