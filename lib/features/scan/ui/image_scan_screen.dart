// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcompanion/core/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
import 'package:permission_handler/permission_handler.dart';

class ImageScanScreen extends StatefulWidget {
  const ImageScanScreen({super.key});

  @override
  State<ImageScanScreen> createState() => _ImageScanScreenState();
}

class _ImageScanScreenState extends State<ImageScanScreen> {
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _foodData;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.status;
    final photos = await Permission.photos.status;

    if (camera.isDenied || photos.isDenied) {
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
    ].request();
  }

  Future<bool> _handlePermissions(ImageSource source) async {
    Permission permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    PermissionStatus status = await permission.status;

    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Permission Required', style: GoogleFonts.poppins()),
            content: Text(
              'Please enable ${source == ImageSource.camera ? 'camera' : 'photos'} access in settings to use this feature.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    if (status.isDenied) {
      status = await permission.request();
      if (status.isDenied) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSection(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_foodData != null)
            _buildResultsSection()
          else
            _buildInitialState(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
          ),
          child: _image != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _image!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _pickImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to scan food image',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Expanded(
      child: ListView(
        children: [
          _buildNutritionCard(),
          const SizedBox(height: 16),
          _buildIngredientsCard(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: Text(
              'Add to Meal Log',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _foodData!['name'] ?? 'Unknown Food',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _foodData!['description'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nutritional Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildNutrientProgressBar(
              'Calories',
              double.parse(_foodData!['calories'].toString()),
              2000, // Daily recommended value
              Colors.orange,
              'kcal',
            ),
            _buildNutrientProgressBar(
              'Protein',
              double.parse(_foodData!['protein'].toString()),
              50, // Daily recommended value
              Colors.red,
              'g',
            ),
            _buildNutrientProgressBar(
              'Carbs',
              double.parse(_foodData!['carbs'].toString()),
              300, // Daily recommended value
              Colors.blue,
              'g',
            ),
            _buildNutrientProgressBar(
              'Fat',
              double.parse(_foodData!['fat'].toString()),
              65, // Daily recommended value
              Colors.green,
              'g',
            ),
            const SizedBox(height: 16),
            Text(
              'Ingredients',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_foodData!['ingredients'] as List).map((ingredient) {
                return Chip(
                  label: Text(
                    ingredient.toString(),
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientProgressBar(
    String label,
    double value,
    double maxValue,
    Color color,
    String unit,
  ) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.poppins()),
              Text(
                '${value.toStringAsFixed(0)} $unit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              if (percentage > 0.95)
                Positioned(
                  right: 0,
                  top: -2,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}% of daily value',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredients & Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _foodData!['description'] ?? 'No details available',
              style: GoogleFonts.poppins(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Expanded(
      child: Center(
        child: Text(
          'Take or upload a photo of your food\nto get nutritional information',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showDialog<XFile>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                if (await _handlePermissions(ImageSource.camera)) {
                  Navigator.pop(
                    // ignore: use_build_context_synchronously
                    context,
                    await picker.pickImage(source: ImageSource.camera),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                if (await _handlePermissions(ImageSource.gallery)) {
                  Navigator.pop(
                    // ignore: use_build_context_synchronously
                    context,
                    await picker.pickImage(source: ImageSource.gallery),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
        _foodData = null;
      });
      await _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      const apiKey = Constants.apiKey;
      const url = Constants.url;

      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''Analyze this food image and provide nutritional estimates in this JSON format:
                {
                  "name": "Food name",
                  "description": "Brief description of the meal",
                  "calories": "Estimate total calories (number only)",
                  "protein": "Estimate protein in grams (number only)",
                  "carbs": "Estimate carbs in grams (number only)",
                  "fat": "Estimate fat in grams (number only)",
                  "ingredients": ["List all visible ingredients"]
                }

                Keep To the point dada, a short description of food item (s) approx 4-5 lines and Please provide realistic nutritional estimates based on visible portions.'''
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      dev.log('Response status: ${response.statusCode}');
      dev.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from response
        String jsonStr =
            text.replaceAll('```json', '').replaceAll('```', '').trim();

        // Find the JSON object
        final startIndex = jsonStr.indexOf('{');
        final endIndex = jsonStr.lastIndexOf('}') + 1;

        if (startIndex == -1 || endIndex == -1) {
          throw Exception('No JSON found in response');
        }

        jsonStr = jsonStr.substring(startIndex, endIndex);
        dev.log('Extracted JSON: $jsonStr');

        try {
          final parsedData = jsonDecode(jsonStr);
          setState(() {
            _foodData = {
              'name': parsedData['name'] ?? 'Unknown Food',
              'description':
                  parsedData['description'] ?? 'No description available',
              'calories': parsedData['calories'] ?? 0,
              'protein': parsedData['protein'] ?? 0,
              'carbs': parsedData['carbs'] ?? 0,
              'fat': parsedData['fat'] ?? 0,
              'ingredients':
                  (parsedData['ingredients'] as List?)?.cast<String>() ?? [],
            };
            _isLoading = false;
          });
        } catch (e) {
          dev.log('JSON Parse Error', error: e);
          throw Exception('Failed to parse food data: $e');
        }
      } else {
        throw Exception(
            'API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Error analyzing image', error: e);
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Exception:')
                  ? e.toString().split('Exception: ')[1]
                  : 'Failed to analyze image',
              style: GoogleFonts.poppins(),
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _analyzeImage,
            ),
          ),
        );
      }
    }
  }
}
