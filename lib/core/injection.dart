import 'package:get_it/get_it.dart';
import 'package:healthcompanion/features/chat/cubit/chat_cubit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/logs/cubit/meal_log_cubit.dart';
import '../features/logs/data/repositories/meal_log_repository.dart';
import '../features/product/data/repo/product_repository.dart';
import '../features/product/logic/cubit/product_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Scanner Controller
  getIt.registerFactory(
    () => MobileScannerController(
      formats: const [BarcodeFormat.all],
      detectionSpeed: DetectionSpeed.normal,
    ),
  );

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepository());
  getIt.registerLazySingleton<MealLogRepository>(
    () => MealLogRepository(getIt<SharedPreferences>()),
  );

  // Cubits
  getIt.registerFactory(() => ProductCubit(getIt()));
  getIt.registerFactory<MealLogCubit>(
    () => MealLogCubit(getIt<MealLogRepository>()),
  );

  getIt.registerFactory(() => ChatCubit(
        scannerController: getIt<MobileScannerController>(),
        prefs: getIt<SharedPreferences>(),
      ));
}
