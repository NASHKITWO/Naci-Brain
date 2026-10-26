# Naci Brain

> Fast-paced math puzzle game. Solve, combo, climb.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

---

## Features

- **5 game modes**: Classic, Endless, Time Attack, Rush, Zen
- **5 power-ups**: Time Freeze, Double Score, Hint, Auto Solve, Slow Motion
- **Adaptive difficulty** that rises as you play (every 10 questions, or every
  10 seconds in Rush)
- **Combo system** with up to a x10 multiplier
- **Achievements** and **daily challenges** that pay out real rewards
- **Daily spin** for coins and gems
- **Saved progress**: XP, level, coins, gems, high scores, login streak

## Design

A calm dark interface built from just three colors: a dark neutral, one mint
accent, and one coral alert color. No gradients, glows or emoji; icons are
monochrome Material icons.

## Getting started

```bash
git clone <repository-url>
cd Naci-Brain-main
flutter pub get
flutter run
```

Run the tests with `flutter test`.

## Dependencies

| Package | Use |
|---------|-----|
| `provider` | State management |
| `shared_preferences` | Local persistence |

## Project structure

```
lib/
├── main.dart
├── models/       Question, GameResult, Achievement, DailyChallenge
├── providers/    GameProvider (game state and rules)
├── services/     QuestionGenerator, StorageService (saved data)
├── utils/        Constants, AppTheme and AppColors
├── widgets/      AppCard/AppButton and other shared UI, AnswerCard, PowerUpBar
└── screens/      Splash, Home, ModeSelection, Game, Result, Daily, Stats, Achievements
```

## Developer

**Naci Brain** was created and developed by:

**Muhammad Ikhsan**
Teknik Informatika, Universitas Pamulang
ican3192@gmail.com

## License

MIT License. See [LICENSE](LICENSE). The copyright notice of the original
project is kept as the license requires.
