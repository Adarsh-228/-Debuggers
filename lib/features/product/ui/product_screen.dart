import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthcompanion/features/product/data/models/detailed_product_model.dart';
import 'package:healthcompanion/features/product/data/repo/product_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/cubit/product_cubit.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late MobileScannerController controller;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _checkPermission();
    context.read<ProductCubit>().reset();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  void _startScanning() {
    setState(() => isScanning = true);
    controller = MobileScannerController();
    context.read<ProductCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        context.read<ProductCubit>().reset();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Scan Product'),
          actions: [
            if (isScanning)
              IconButton(
                icon: Icon(
                  controller.torchEnabled
                      ? Icons.flashlight_on
                      : Icons.flashlight_off,
                ),
                onPressed: () => controller.toggleTorch(),
              ),
          ],
        ),
        body: BlocConsumer<ProductCubit, ProductState>(
          listener: (context, state) {
            if (state is ProductError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is ProductLoaded) {
              _stopScanning();
            }
          },
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductLoaded) {
              return _buildProductInfo(state);
            }
            return _buildScanner(context);
          },
        ),
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    if (!isScanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://www.scandit.com/wp-content/uploads/2023/01/SparkScan_ergonomic_scanner_retail.jpg',
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Start Scanning'),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan the QR code of the product to get the information',
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null && code.isNotEmpty && context.mounted) {
                controller.stop();
                context.read<ProductCubit>().scanProduct(code);
                break;
              }
            }
          },
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: const Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 2),
                    bottom: BorderSide(color: Colors.white, width: 2),
                    left: BorderSide(color: Colors.white, width: 2),
                    right: BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(ProductLoaded state) {
    final basic = state.basicProduct;
    final detailed = state.detailedProduct;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Image.network(
                      basic.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  basic.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (basic.brands != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    basic.brands!,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Scores Row
                _buildScoresSection(detailed),

                const SizedBox(height: 16),

                // Nutrition Facts Card
                _buildNutritionCard(detailed.nutrients),
                const SizedBox(height: 16),

                // Nutrient Levels
                _buildNutrientLevelsCard(detailed.nutrientLevels),
                const SizedBox(height: 16),
                // Ingredients
                if (detailed.ingredients.isNotEmpty)
                  _buildInteractiveListTile(
                    title: 'Ingredients',
                    items: detailed.ingredients,
                    icon: Icons.receipt_long_rounded,
                    isExpandable: true,
                  ),

                // Allergens Warning
                const SizedBox(height: 16),
                if (detailed.allergens.isNotEmpty) ...[
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Allergens',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detailed.allergens.join(', '),
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Additional Information
                _buildInfoSection('Product Details', [
                  if (basic.quantity != null)
                    InfoRow('Quantity', basic.quantity!),
                  if (detailed.servingSize != null)
                    InfoRow('Serving Size', detailed.servingSize!),
                  if (detailed.packaging.isNotEmpty)
                    InfoRow('Packaging', detailed.packaging.join(', ')),
                  if (detailed.origins != null)
                    InfoRow('Origin', detailed.origins!),
                  if (detailed.categories.isNotEmpty)
                    InfoRow('Categories', detailed.categories.join(', ')),
                ]),

                const SizedBox(height: 24),
                Center(
                  child: FilledButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Another Product'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoresSection(DetailedProductModel detailed) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Scores',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScoreIndicator(
                    'Nutri-Score',
                    detailed.nutriScore?.toUpperCase() ?? 'N/A',
                    _getNutriScoreDescription(detailed.nutriScore),
                    _getNutriScoreColor(detailed.nutriScore),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNovaScore(detailed.novaGroup),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildScoreIndicator(
                    'Eco-Score',
                    detailed.ecoscore?.toUpperCase() ?? 'N/A',
                    _getEcoScoreDescription(detailed.ecoscore),
                    _getEcoScoreColor(detailed.ecoscore),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(
      String title, String score, String description, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              score,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNovaScore(String? novaGroup) {
    final group = int.tryParse(novaGroup ?? '') ?? 0;
    final descriptions = [
      'N/A',
      'Unprocessed',
      'Processed Culinary',
      'Processed Foods',
      'Ultra-processed'
    ];
    final colors = [
      Colors.grey,
      Colors.green,
      Colors.lightGreen,
      Colors.orange,
      Colors.red,
    ];

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colors[group].withOpacity(0.1),
            border: Border.all(color: colors[group], width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NOVA',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors[group],
                ),
              ),
              Text(
                group.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors[group],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Processing',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          descriptions[group],
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getNutriScoreDescription(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return 'Excellent nutritional quality';
      case 'b':
        return 'Good nutritional quality';
      case 'c':
        return 'Average nutritional quality';
      case 'd':
        return 'Poor nutritional quality';
      case 'e':
        return 'Unhealthy nutritional quality';
      default:
        return 'Not available';
    }
  }

  String _getEcoScoreDescription(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return 'Very low environmental impact';
      case 'b':
        return 'Low environmental impact';
      case 'c':
        return 'Moderate environmental impact';
      case 'd':
        return 'High environmental impact';
      case 'e':
        return 'Very high environmental impact';
      default:
        return 'Not available';
    }
  }

  Color _getNutriScoreColor(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return Colors.green;
      case 'b':
        return Colors.lightGreen;
      case 'c':
        return Colors.yellow;
      case 'd':
        return Colors.orange;
      case 'e':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getEcoScoreColor(String? score) {
    switch (score?.toLowerCase()) {
      case 'a':
        return Colors.green;
      case 'b':
        return Colors.lightGreen;
      case 'c':
        return Colors.yellow;
      case 'd':
        return Colors.orange;
      case 'e':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNutritionCard(NutrimentsModel nutrients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Facts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMainNutrients(nutrients),
            const Divider(),
            _buildMineralsSection(nutrients),
            if (nutrients.transFat != null) ...[
              const Divider(),
              _buildFatTypes(nutrients),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainNutrients(NutrimentsModel nutrients) {
    return Column(
      children: [
        _buildNutrientRow(
          'Energy',
          '${nutrients.energy} kcal',
          isHighlighted: true,
        ),
        const SizedBox(height: 8),
        _buildNutrientBarRow('Proteins', nutrients.proteins, 50, Colors.green),
        _buildNutrientBarRow(
            'Carbohydrates', nutrients.carbohydrates, 100, Colors.orange),
        _buildNutrientBarRow('Fat', nutrients.fat, 50, Colors.red),
        _buildNutrientBarRow('Fiber', nutrients.fiber, 25, Colors.brown),
        _buildNutrientBarRow('Sugars', nutrients.sugars, 25, Colors.pink),
      ],
    );
  }

  Widget _buildMineralsSection(NutrimentsModel nutrients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minerals & Vitamins',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildMineralRow('Calcium', '${nutrients.calcium}mg'),
        _buildMineralRow('Iron', '${nutrients.iron}mg'),
        _buildMineralRow('Sodium', '${nutrients.sodium}mg'),
      ],
    );
  }

  Widget _buildFatTypes(NutrimentsModel nutrients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fat Types',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildNutrientRow('Saturated Fat', '${nutrients.saturatedFat}g'),
        if (nutrients.transFat != null)
          _buildNutrientRow('Trans Fat', '${nutrients.transFat}g',
              textColor: nutrients.transFat! > 0 ? Colors.red : null),
      ],
    );
  }

  Widget _buildNutrientBarRow(
      String label, double value, double maxValue, Color color) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.poppins()),
              Text('${value}g',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildMineralRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(
    String label,
    String value, {
    bool isHighlighted = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: isHighlighted ? FontWeight.w600 : null,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _stopScanning() {
    setState(() => isScanning = false);
    controller.dispose();
  }

  Widget _buildNutrientLevelsCard(NutrientLevels levels) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrient Levels',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientLevelIndicator('Fat', levels.fat),
            _buildNutrientLevelIndicator('Saturated Fat', levels.saturatedFat),
            _buildNutrientLevelIndicator('Sugars', levels.sugars),
            _buildNutrientLevelIndicator('Salt', levels.salt),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientLevelIndicator(String nutrient, String level) {
    final colors = {
      'low': Colors.green,
      'moderate': Colors.orange,
      'high': Colors.red,
      'unknown': Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nutrient,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors[level.toLowerCase()]?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors[level.toLowerCase()] ?? Colors.grey,
                  ),
                ),
                child: Text(
                  level.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: colors[level.toLowerCase()],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: level.toLowerCase() == 'low'
                  ? 0.3
                  : level.toLowerCase() == 'moderate'
                      ? 0.6
                      : level.toLowerCase() == 'high'
                          ? 0.9
                          : 0.0,
              backgroundColor: Colors.grey[200],
              color: colors[level.toLowerCase()],
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<InfoRow> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveListTile({
    required String title,
    required List<String> items,
    required IconData icon,
    bool isExpandable = false,
    Color? iconColor,
  }) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    items.map((item) => _buildIngredientChip(item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientChip(String ingredient) {
    // Define common allergens for highlighting
    final commonAllergens = {
      'milk': Colors.blue[100],
      'egg': Colors.yellow[100],
      'nuts': Colors.brown[100],
      'peanut': Colors.brown[100],
      'soy': Colors.green[100],
      'wheat': Colors.orange[100],
      'fish': Colors.blue[100],
      'shellfish': Colors.red[100],
    };

    // Check if ingredient contains any allergen
    final allergenMatch = commonAllergens.entries.firstWhere(
      (entry) => ingredient.toLowerCase().contains(entry.key),
      orElse: () => const MapEntry('none', null),
    );

    final isAllergen = allergenMatch.value != null;
    final backgroundColor = allergenMatch.value ?? Colors.grey[200];

    return Chip(
      label: Text(
        ingredient,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isAllergen ? Colors.black87 : Colors.black54,
          fontWeight: isAllergen ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor: backgroundColor,
      side: isAllergen
          ? BorderSide(
              color: backgroundColor!.withRed(backgroundColor.red + 50))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label.isNotEmpty ? label : 'N/A',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}

// Add these extension methods for better visual indicators
extension StringX on String {
  String get cleanupLabel => split('_')
      .map((word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}
