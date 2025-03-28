import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthcompanion/features/chat/cubit/chat_cubit.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'core/injection.dart';
import 'core/routes.dart';
import 'features/product/logic/cubit/product_cubit.dart';
import 'features/logs/cubit/meal_log_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize OpenFoodFacts
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'Health Companion',
    version: '1.0.0',
    system: 'Android',
  );

  await setupInjection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProductCubit>()),
        BlocProvider(create: (_) => getIt<MealLogCubit>()..loadLogs()),
        BlocProvider(create: (_) => getIt<ChatCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Health Companion',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
        ),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
