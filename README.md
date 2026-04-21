# Flutter Clean Starter

Skip the boilerplate. Start building Flutter apps the right way.

A command-line tool that generates production-ready Flutter projects with
Clean Architecture, BLoC/Cubit/Riverpod, Dio, and GetIt — all wired up
from a single interactive command.

## Features

- Clean Architecture folder structure out of the box
- Choose your state management — BLoC, Cubit, or Riverpod
- Select only the feature modules you need
- Dio client with interceptor and PrettyDioLogger pre-configured
- GetIt + Injectable dependency injection ready for build_runner
- Optional Flutter Flavors setup (dev / staging / prod)
- Runs flutter pub get automatically

## Installation

```bash
dart pub global activate flutter_scaffold
```

Make sure your PATH includes the pub cache bin directory:

```bash
# Add to your .zshrc or .bashrc
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## Usage

```bash
flutter_scaffold create
```

The CLI will guide you through:

1. Project name and bundle ID
2. State management (BLoC / Cubit / Riverpod)
3. Feature modules (auth, home, profile, settings, onboarding)
4. Flutter Flavors setup

## Generated structure

lib/
├── core/
│   ├── constants/
│   ├── error/
│   ├── network/        # Dio client + interceptor
│   ├── router/         # GoRouter setup
│   ├── theme/
│   └── usecase/        # UseCase base class
├── di/                 # GetIt + Injectable
└── features/
└── auth/           # per selected feature
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
├── bloc/
├── pages/
└── widgets/

## After generation

```bash
cd your_project
flutter pub run build_runner build --delete-conflicting-outputs
code .
```

## Requirements

- Dart SDK >= 3.0.0
- Flutter SDK installed and on PATH

## License

MIT