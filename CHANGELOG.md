# Changelog

## 0.1.3

- Updated generated `injection.dart` to auto-register `SharedPreferences`, `ApiInterceptor`, and `DioClient` with `registerLazySingleton`.
- Made generated DI setup idempotent using `isRegistered<T>()` checks.

## 0.1.2

- Added GET,PUT,POST and PATCH methods with DioClient

## 0.1.0+1

- Initial release
- Interactive project scaffolding with Clean Architecture
- BLoC, Cubit, and Riverpod support
- Dynamic feature module generation
- Dio client with interceptor pre-configured
- GetIt + Injectable dependency injection setup
- Optional Flutter Flavors configuration
