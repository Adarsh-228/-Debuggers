import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthcompanion/core/constants.dart';
import 'package:healthcompanion/features/chat/data/models/chat_message.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcompanion/features/shared/models/user_health_preferences.dart';

class ChatCubit extends Cubit<List<ChatMessage>> {
  final MobileScannerController _scannerController;
  final SharedPreferences _prefs;
  UserHealthPreferences? _healthPreferences;

  ChatCubit({
    required MobileScannerController scannerController,
    required SharedPreferences prefs,
  })  : _scannerController = scannerController,
        _prefs = prefs,
        super([]) {
    _loadHealthPreferences();
  }

  UserHealthPreferences? get healthPreferences => _healthPreferences;

  Future<void> _loadHealthPreferences() async {
    final prefsJson = _prefs.getString('health_preferences');
    if (prefsJson != null) {
      _healthPreferences = UserHealthPreferences.fromJson(
        jsonDecode(prefsJson),
      );
    }
  }

  Future<void> saveHealthPreferences(UserHealthPreferences prefs) async {
    _healthPreferences = prefs;
    await _prefs.setString('health_preferences', jsonEncode(prefs.toJson()));
  }

  String get _systemPrompt {
    String basePrompt = '''
    You are a helpful nutritionist assistant. Your task is to help user with suggestions and not speculation.
    When asked for a grocery list:
    - Indian Diet Please
    - Consider user preferences & indian food available in market
    - Use ONLY plain text formatting (NO markdown, NO **, NO headers)
    - Organize in categories using [Category Name] format
    - Each item must start with - [ ] 
    - Include quantities and units
    - Add ❄️ after items that can be frozen
    - Example format:
        [Produce]
        - [ ] 5 Bananas
        - [ ] 2 Avocados ❄️
    - Avoid any markdown formatting
    - Never use bold/italic text
    - Consider user preferences: 
    ${_healthPreferences?.toPrompt() ?? 'No preferences set'}
    ''';

    if (_healthPreferences != null) {
      return '''
$basePrompt

${_healthPreferences!.toPrompt()}
''';
    }

    return basePrompt;
  }

  String get _chatHistory {
    return state.map((msg) {
      if (msg.type == MessageType.product) {
        return "Product Scan: ${msg.metadata?['name']} - ${msg.metadata?['nutrition']}";
      }
      return "${msg.isUser ? 'User' : 'Assistant'}: ${msg.content}";
    }).join('\n');
  }

  Future<void> sendMessage(String message, {bool isList = false}) async {
    emit([...state, ChatMessage(content: message, isUser: true)]);

    try {
      const apiKey = Constants.apiKey;
      const url = Constants.url;

      String prompt = isList
          ? """
    - Generate a 1-week grocery list for a diet plan that matches these requirements:
    - Keep it organized by food categories
    - Include quantities needed for the week
    - Consider storage/freshness
    - Add optional checkbox formatting
    - Prompt: $message
    """
          : message;

      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
              $_systemPrompt
              
              Chat History:
              $_chatHistory
              
              User: $prompt
              Assistant: '''
                }
              ]
            }
          ]
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final reply =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        // Check if this is a list response
        final isListResponse =
            RegExp(r'^\[.*\]$', multiLine: true).hasMatch(reply) &&
                reply.contains('- [ ]');

        emit([
          ...state,
          ChatMessage(
            content: reply,
            isUser: false,
            type: isListResponse ? MessageType.list : MessageType.text,
          ),
        ]);
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      emit([
        ...state,
        ChatMessage(
          content: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          type: MessageType.error,
        ),
      ]);
    }
  }

  Future<void> scanBarcode(BuildContext context) async {
    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        Navigator.pop(context, barcodes.first.rawValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (result != null) {
        final response = await http.get(
          Uri.parse(
              'https://world.openfoodfacts.org/api/v0/product/$result.json'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 1) {
            final product = data['product'];
            final nutrition = product['nutriments'];

            final metadata = {
              'name': product['product_name'],
              'nutrition': {
                'calories': nutrition['energy-kcal_100g'] ?? "N/A",
                'protein': nutrition['proteins_100g'] ?? "N/A",
                'carbs': nutrition['carbohydrates_100g'] ?? "N/A",
                'fat': nutrition['fat_100g'] ?? "N/A",
              },
              'barcode': result,
            };

            emit([
              ...state,
              ChatMessage(
                content: 'Scanned: ${metadata['name']}',
                isUser: true,
                type: MessageType.product,
                metadata: metadata,
              ),
            ]);

            // Auto-generate insights
            sendMessage(
                'What can you tell me about the nutritional value of this ${metadata['name']}?');
          }
        }
      }
    } catch (e) {
      emit([
        ...state,
        ChatMessage(
          content: 'Failed to scan product. Please try again.',
          isUser: false,
          type: MessageType.error,
        ),
      ]);
    }
  }

  void clearChat() {
    emit([]);
  }
}
