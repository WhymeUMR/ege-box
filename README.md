# Ege Box

Приложение-помощник для подготовки к ЕГЭ. Flutter, feature-first архитектура, state management — `provider`.

## Структура

```
lib/
├── main.dart                 # точка входа
├── app.dart                  # корневой виджет, MultiProvider + MaterialApp
├── core/                     # общая инфраструктура
│   ├── constants/            # строки, ключи, размеры
│   ├── theme/                # темы (light/dark)
│   ├── routing/              # маршрутизация
│   └── utils/                # вспомогательные функции
├── shared/
│   └── widgets/              # переиспользуемые виджеты
└── features/
    └── <feature>/
        ├── data/             # источники данных, репозитории, DTO
        ├── domain/           # модели, бизнес-логика, интерфейсы
        └── presentation/
            ├── pages/        # экраны
            ├── widgets/      # виджеты фичи
            └── providers/    # ChangeNotifier-провайдеры
```

Каждая новая фича добавляется как `lib/features/<name>/` по тому же шаблону.

## Команды

```bash
flutter pub get          # установка зависимостей
flutter run              # запуск
flutter test             # тесты
flutter analyze          # статанализ
```
