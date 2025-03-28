import 'package:go_router/go_router.dart';
import '../features/home/ui/home_screen.dart';
import '../features/splash/ui/splash_screen.dart';
import '../features/product/ui/product_screen.dart';
import '../features/scan/ui/image_scan_screen.dart';
import 'package:healthcompanion/features/logs/ui/meal_history.dart';
import 'package:healthcompanion/features/logs/ui/meal_log_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/scan', builder: (_, __) => const ProductScreen()),
    GoRoute(path: '/history', builder: (_, __) => const MealHistory()),
    GoRoute(path: '/meal-log', builder: (_, __) => const MealLogScreen()),
    GoRoute(path: '/image-scan', builder: (_, __) => const ImageScanScreen()),
  ],
);
