import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthcompanion/features/chat/ui/chat_screen.dart';
import 'package:healthcompanion/features/chat/cubit/chat_cubit.dart';
import 'package:healthcompanion/features/logs/ui/meal_log_screen.dart';
import 'package:healthcompanion/features/scan/ui/image_scan_screen.dart';
import 'package:healthcompanion/features/chat/ui/health_preferences_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.green.shade50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Health Companion',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: HealthPreferencesSheet(
                  initialPreferences:
                      context.read<ChatCubit>().healthPreferences,
                  onSave: (prefs) async {
                    await context
                        .read<ChatCubit>()
                        .saveHealthPreferences(prefs);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDailyLogTab(),
          _buildChatBotTab(),
          _buildScanTab(),
          _buildImageScanTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.purple.shade50,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Daily Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Image Scan',
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Scan Barcode',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Point your camera at a product barcode to get nutritional information',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              context.push('/scan');
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageScanTab() {
    return const ImageScanScreen();
  }

  Widget _buildChatBotTab() {
    return const ChatScreen();
  }

  Widget _buildDailyLogTab() {
    return const MealLogScreen();
  }
}
