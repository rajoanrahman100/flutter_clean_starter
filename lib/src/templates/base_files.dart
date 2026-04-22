import '../models/project_config.dart';

class BaseFiles {
  static Map<String, String> generate({required ProjectConfig config}) {
    final files = <String, String>{
      'lib/core/error/failures.dart': _failures(),
      'lib/core/error/exceptions.dart': _exceptions(),
      'lib/core/usecase/usecase.dart': _usecase(),
      'lib/core/network/dio_client.dart': _dioClient(),
      'lib/core/network/api_interceptor.dart': _apiInterceptor(),
      'lib/core/constants/app_constants.dart': _appConstants(config.useFlavors),
      'lib/core/router/app_router.dart': _appRouter(config.features),
      'lib/di/injection.dart': _injection(
        config.features,
        config.stateManagement,
      ),
      'lib/di/injection.config.dart': _injectionConfig(),
      'lib/main.dart': _main(config.useFlavors),
      'lib/app.dart': _app(
        config.projectName,
        config.useFlavors,
        config.features,
        config.stateManagement,
      ),
    };

    // Generate boilerplate for every selected feature
    for (final feature in config.features) {
      files.addAll(_featureFiles(feature, config.stateManagement));
    }

    return files;
  }

  // ── Core files ────────────────────────────────────────────────

  static String _failures() => '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}
''';

  static String _exceptions() => '''
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);
}
''';

  static String _usecase() => '''
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  const UseCase();

  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
''';

  static String _dioClient() => '''
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import 'api_interceptor.dart';

@lazySingleton
class DioClient {
  late final Dio _dio;

  DioClient(ApiInterceptor apiInterceptor) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      apiInterceptor,
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Dio get dio => _dio;
}
''';

  static String _apiInterceptor() => '''
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@lazySingleton
class ApiInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: attach auth token from secure storage
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('Dio error: \${err.message}');
    super.onError(err, handler);
  }
}
''';

  static String _appConstants(bool useFlavors) {
    if (useFlavors) {
      return '''
import '../config/app_config.dart';

class AppConstants {
  static String get baseUrl => AppConfig.current.baseUrl;
  static String get appName => AppConfig.current.appName;
  static const int connectionTimeout = 30;
}
''';
    }

    return '''
class AppConstants {
  static const String baseUrl = 'https://api.yourserver.com';
  static const String appName = 'App';
  static const int connectionTimeout = 30;
}
''';
  }

  static String _appRouter(List<String> features) {
    final imports = features.map((f) =>
    "import '../../features/$f/presentation/pages/${f}_page.dart';",
    ).join('\n');

    final routes = features.map((f) => '''
      GoRoute(
        path: '/${f == features.first ? '' : f}',
        builder: (context, state) => const ${_className(f)}Page(),
      ),''').join('\n');

    return '''
import 'package:go_router/go_router.dart';
$imports

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
$routes
    ],
  );
}
''';
  }

  static String _injection(List<String> features, String stateManagement) {
    final isCubit = stateManagement == 'Cubit';
    final blocFile = isCubit ? 'cubit' : 'bloc';
    final blocType = isCubit ? 'Cubit' : 'Bloc';

    final featureImports = features.map((feature) {
      return '''
import '../features/$feature/domain/repositories/${feature}_repository.dart';
import '../features/$feature/domain/usecases/get_${feature}_usecase.dart';
import '../features/$feature/data/repositories/${feature}_repository_impl.dart';
import '../features/$feature/presentation/bloc/${feature}_$blocFile.dart';
''';
    }).join('\n');

    final featureRegistrations = features.map((feature) {
      final className = _className(feature);
      return '''
  if (!sl.isRegistered<${className}Repository>()) {
    sl.registerLazySingleton<${className}Repository>(
      () => const ${className}RepositoryImpl(),
    );
  }
  if (!sl.isRegistered<Get${className}UseCase>()) {
    sl.registerLazySingleton<Get${className}UseCase>(
      () => Get${className}UseCase(sl<${className}Repository>()),
    );
  }
  if (!sl.isRegistered<${className}$blocType>()) {
    sl.registerFactory<${className}$blocType>(
      () => ${className}$blocType(sl<Get${className}UseCase>()),
    );
  }
''';
    }).join('\n');

    return '''
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_interceptor.dart';
import '../core/network/dio_client.dart';
$featureImports
import 'injection.config.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await sl.init();

  final sharedPreferences = await SharedPreferences.getInstance();
  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  }

  if (!sl.isRegistered<ApiInterceptor>()) {
    sl.registerLazySingleton<ApiInterceptor>(() => ApiInterceptor());
  }

  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(
      () => DioClient(sl<ApiInterceptor>()),
    );
  }

$featureRegistrations
}
''';
  }

  static String _injectionConfig() => '''
// GENERATED CODE — DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// ignore_for_file: type=lint
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

extension GetItInjectableX on GetIt {
  GetIt init({
    String? environment,
    EnvironmentFilter? environmentFilter,
  }) {
    return this;
  }
}
''';

  static String _main(bool useFlavors) => '''
import 'package:flutter/material.dart';
import 'di/injection.dart';
${useFlavors ? "import 'core/config/app_config.dart';\nimport 'core/config/flavor.dart';" : ''}
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
${useFlavors ? '  AppConfig.setFlavor(Flavor.prod);' : ''}
  await configureDependencies();
  runApp(const App());
}
''';

  static String _app(
    String projectName,
    bool useFlavors,
    List<String> features,
    String stateManagement,
  ) {
    final titleValue = useFlavors ? 'AppConstants.appName' : "'$projectName'";

    if (stateManagement == 'Riverpod') {
      return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
${useFlavors ? "import 'core/constants/app_constants.dart';" : ''}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: $titleValue,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );

    return ProviderScope(child: app);
  }
}
''';
    }

    final suffix = stateManagement == 'Cubit' ? 'cubit' : 'bloc';
    final typeName = stateManagement == 'Cubit' ? 'Cubit' : 'Bloc';
    final blocImports = features
        .map((f) => "import 'features/$f/presentation/bloc/${f}_$suffix.dart';")
        .join('\n');
    final eventImports = stateManagement == 'Cubit'
        ? ''
        : features
            .map((f) => "import 'features/$f/presentation/bloc/${f}_event.dart';")
            .join('\n');
    final providers = features.map((f) {
      final className = _className(f);
      if (stateManagement == 'Cubit') {
        return "        BlocProvider<${className}$typeName>(create: (_) => sl<${className}$typeName>()..load$className()),";
      }
      return "        BlocProvider<${className}$typeName>(create: (_) => sl<${className}$typeName>()..add(const Load${className}Event())),";
    }).join('\n');

    return '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'di/injection.dart';
${useFlavors ? "import 'core/constants/app_constants.dart';" : ''}
$blocImports
$eventImports

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: $titleValue,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );

    return MultiBlocProvider(
      providers: [
$providers
      ],
      child: app,
    );
  }
}
''';
  }

  // ── Per-feature file generation ───────────────────────────────

  static Map<String, String> _featureFiles(
      String feature,
      String stateManagement,
      ) {
    final className = _className(feature);
    final useBlocPattern = stateManagement != 'Riverpod';

    final files = <String, String>{
      'lib/features/$feature/domain/entities/${feature}_entity.dart':
      _entity(feature, className),
      'lib/features/$feature/domain/repositories/${feature}_repository.dart':
      _repository(feature, className),
      'lib/features/$feature/domain/usecases/get_${feature}_usecase.dart':
      _featureUsecase(feature, className),
      'lib/features/$feature/data/models/${feature}_model.dart':
      _model(feature, className),
      'lib/features/$feature/data/repositories/${feature}_repository_impl.dart':
      _repositoryImpl(feature, className),
      'lib/features/$feature/presentation/pages/${feature}_page.dart':
      _page(feature, className, stateManagement),
    };

    if (useBlocPattern) {
      files.addAll({
        'lib/features/$feature/presentation/bloc/${feature}_bloc.dart':
        _bloc(feature, className, stateManagement),
        'lib/features/$feature/presentation/bloc/${feature}_event.dart':
        _event(feature, className),
        'lib/features/$feature/presentation/bloc/${feature}_state.dart':
        _state(feature, className),
      });
    } else {
      files['lib/features/$feature/presentation/bloc/${feature}_notifier.dart'] =
          _notifier(feature, className);
    }

    return files;
  }

  static String _entity(String feature, String className) => '''
import 'package:equatable/equatable.dart';

class ${className}Entity extends Equatable {
  final String id;

  const ${className}Entity({required this.id});

  @override
  List<Object?> get props => [id];
}
''';

  static String _repository(String feature, String className) => '''
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${feature}_entity.dart';

abstract class ${className}Repository {
  Future<Either<Failure, ${className}Entity>> get${className}();
}
''';

  static String _featureUsecase(String feature, String className) => '''
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${feature}_entity.dart';
import '../repositories/${feature}_repository.dart';

@lazySingleton
class Get${className}UseCase extends UseCase<${className}Entity, NoParams> {
  final ${className}Repository repository;

  Get${className}UseCase(this.repository);

  @override
  Future<Either<Failure, ${className}Entity>> call(NoParams params) {
    return repository.get${className}();
  }
}
''';

  static String _model(String feature, String className) => '''
import '../../domain/entities/${feature}_entity.dart';

class ${className}Model extends ${className}Entity {
  const ${className}Model({required super.id});

  factory ${className}Model.fromJson(Map<String, dynamic> json) {
    return ${className}Model(id: json['id'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''';

  static String _repositoryImpl(String feature, String className) => '''
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/${feature}_entity.dart';
import '../../domain/repositories/${feature}_repository.dart';

@LazySingleton(as: ${className}Repository)
class ${className}RepositoryImpl implements ${className}Repository {
  // TODO: inject remote and local data sources

  const ${className}RepositoryImpl();

  @override
  Future<Either<Failure, ${className}Entity>> get${className}() async {
    try {
      // TODO: call datasource
      throw const ServerException('Not implemented yet');
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
''';

  static String _bloc(
      String feature, String className, String stateManagement) {
    final superClass =
    stateManagement == 'Cubit' ? 'Cubit<${className}State>' : 'Bloc<${className}Event, ${className}State>';

    if (stateManagement == 'Cubit') {
      return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_${feature}_usecase.dart';
import '../../../../core/usecase/usecase.dart';
import '${feature}_state.dart';

@injectable
class ${className}Cubit extends $superClass {
  final Get${className}UseCase _get${className}UseCase;

  ${className}Cubit(this._get${className}UseCase) : super( ${className}Initial());

  Future<void> load${className}() async {
    emit(const ${className}Loading());
    final result = await _get${className}UseCase(NoParams());
    result.fold(
      (failure) => emit(${className}Error(failure.message)),
      (data) => emit(${className}Loaded(data)),
    );
  }
}
''';
    }

    return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_${feature}_usecase.dart';
import '../../../../core/usecase/usecase.dart';
import '${feature}_event.dart';
import '${feature}_state.dart';

@injectable
class ${className}Bloc extends $superClass {
  final Get${className}UseCase _get${className}UseCase;

  ${className}Bloc(this._get${className}UseCase) : super( ${className}Initial()) {
    on<Load${className}Event>(_onLoad);
  }

  Future<void> _onLoad(
    Load${className}Event event,
    Emitter<${className}State> emit,
  ) async {
    emit(const ${className}Loading());
    final result = await _get${className}UseCase(NoParams());
    result.fold(
      (failure) => emit(${className}Error(failure.message)),
      (data) => emit(${className}Loaded(data)),
    );
  }
}
''';
  }

  static String _event(String feature, String className) => '''
import 'package:equatable/equatable.dart';

abstract class ${className}Event extends Equatable {
  const ${className}Event();

  @override
  List<Object?> get props => [];
}

class Load${className}Event extends ${className}Event {
  const Load${className}Event();
}
''';

  static String _state(String feature, String className) => '''
import 'package:equatable/equatable.dart';
import '../../domain/entities/${feature}_entity.dart';

abstract class ${className}State extends Equatable {
  const ${className}State();

  @override
  List<Object?> get props => [];
}

class ${className}Initial extends ${className}State {
  const ${className}Initial();
}

class ${className}Loading extends ${className}State {
  const ${className}Loading();
}

class ${className}Loaded extends ${className}State {
  final ${className}Entity data;
  const ${className}Loaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ${className}Error extends ${className}State {
  final String message;
  const ${className}Error(this.message);

  @override
  List<Object?> get props => [message];
}
''';

  static String _notifier(String feature, String className) => '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/${feature}_entity.dart';

class ${className}Notifier extends AsyncNotifier<${className}Entity?> {
  @override
  Future<${className}Entity?> build() async {
    return null;
  }

  Future<void> load() async {
    state = const AsyncLoading();
    // TODO: call Get${className}UseCase
  }
}

final ${feature}Provider =
    AsyncNotifierProvider<${className}Notifier, ${className}Entity?>(
  ${className}Notifier.new,
);
''';

  static String _page(
      String feature, String className, String stateManagement) {
    if (stateManagement == 'Riverpod') {
      return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bloc/${feature}_notifier.dart';

class ${className}Page extends ConsumerWidget {
  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${feature}Provider);
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: state.when(
        data: (_) => const Center(child: Text('$className loaded')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
      ),
    );
  }
}
''';
    }

    final providerType =
    stateManagement == 'Cubit' ? '${className}Cubit' : '${className}Bloc';
    final stateClass =
    stateManagement == 'Cubit' ? '${className}State' : '${className}State';

    return '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${feature}_${stateManagement == 'Cubit' ? 'cubit' : 'bloc'}.dart';
import '../bloc/${feature}_state.dart';

class ${className}Page extends StatelessWidget {
  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: BlocBuilder<$providerType, $stateClass>(
        builder: (context, state) {
          if (state is ${className}Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ${className}Error) {
            return Center(child: Text('Error: \${state.message}'));
          }
          if (state is ${className}Loaded) {
            return const Center(child: Text('$className loaded'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
''';
  }

  // ── Helpers ───────────────────────────────────────────────────

  /// Converts "my_feature" → "MyFeature"
  static String _className(String feature) {
    return feature
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join();
  }
}
