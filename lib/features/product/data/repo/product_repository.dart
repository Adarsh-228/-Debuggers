import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../models/product_model.dart';
import '../models/detailed_product_model.dart';

class ProductRepository {
  static const baseUrl = 'https://world.openfoodfacts.org/api/v3/product';

  String _normalizeTag(String tag) {
    // Remove 'en:' prefix
    final withoutPrefix = tag.replaceAll('en:', '');

    // Replace hyphens with spaces
    final withSpaces = withoutPrefix.replaceAll('-', ' ');

    // Capitalize first letter of each word
    final words = withSpaces.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    });

    return capitalizedWords.join(' ');
  }

  List<String> _normalizeTags(List<dynamic> tags) {
    return tags.map((tag) => _normalizeTag(tag.toString())).toList();
  }

  Future<(ProductModel?, DetailedProductModel?)> getProductByBarcode(
      String barcode) async {
    try {
      // First API call using OpenFoodFacts package
      final config = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.getProductV3(config);
      final response = await http.get(Uri.parse('$baseUrl/$barcode.json'));

      if (response.statusCode == 200) {
        final detailedJson = json.decode(response.body);
        final product = result.product;

        if (result.status == 'success' && product != null) {
          // Basic Model remains same
          final basicModel = ProductModel(
            barcode: barcode,
            name: product.productName ?? 'Unknown',
            imageUrl: product.imageFrontUrl,
            nutriScore: product.nutriscore ?? product.nutriscore,
            nutrients: product.nutriments?.toJson(),
            brands: product.brands,
            quantity: product.quantity,
            ingredients: product.ingredientsText,
            allergens: product.allergens?.names ?? [],
            servingSize: product.servingSize,
            categories: product.categories,
            packaging: product.packaging,
            origins: product.origins,
            labels: product.labels,
            stores: product.stores,
            countries: product.countries,
          );

          // Detailed Model from direct API
          final productData = detailedJson['product'];
          final detailedModel = DetailedProductModel(
            barcode: barcode,
            name: productData['product_name'] ?? 'Unknown',
            imageUrl: productData['image_front_url'],
            nutriScore: productData['nutriscore_grade'],
            nutrients: NutrimentsModel(
              energy:
                  _parseDouble(productData['nutriments']['energy-kcal_100g']),
              proteins:
                  _parseDouble(productData['nutriments']['proteins_100g']),
              carbohydrates:
                  _parseDouble(productData['nutriments']['carbohydrates_100g']),
              fat: _parseDouble(productData['nutriments']['fat_100g']),
              fiber: _parseDouble(productData['nutriments']['fiber_100g']),
              sugars: _parseDouble(productData['nutriments']['sugars_100g']),
              salt: _parseDouble(productData['nutriments']['salt_100g']),
              saturatedFat:
                  _parseDouble(productData['nutriments']['saturated-fat_100g']),
              calcium: _parseDouble(productData['nutriments']['calcium_100g']),
              iron: _parseDouble(productData['nutriments']['iron_100g']),
              vitaminA:
                  _parseDouble(productData['nutriments']['vitamin-a_100g']),
              vitaminC:
                  _parseDouble(productData['nutriments']['vitamin-c_100g']),
              transFat:
                  _parseDouble(productData['nutriments']['trans-fat_100g']),
              cholesterol:
                  _parseDouble(productData['nutriments']['cholesterol_100g']),
              sodium: _parseDouble(productData['nutriments']['sodium_100g']),
            ),
            brands: productData['brands'],
            quantity: productData['quantity'],
            ingredients: _normalizeTags(productData['ingredients_tags'] ?? []),
            allergens: _normalizeTags(productData['allergens_tags'] ?? []),
            servingSize: productData['serving_size'],
            categories: _normalizeTags(productData['categories_tags'] ?? []),
            packaging: _normalizeTags(productData['packaging_tags'] ?? []),
            origins: productData['origins'],
            labels: _normalizeTags(productData['labels_tags'] ?? []),
            stores: productData['stores'],
            countries: List<String>.from(productData['countries_tags'] ?? []),
            novaGroup: productData['nova_group']?.toString(),
            ecoscore: productData['ecoscore_grade'],
            nutrientLevels: NutrientLevels(
              fat: productData['nutrient_levels']?['fat'] ?? 'unknown',
              saturatedFat:
                  productData['nutrient_levels']?['saturated-fat'] ?? 'unknown',
              sugars: productData['nutrient_levels']?['sugars'] ?? 'unknown',
              salt: productData['nutrient_levels']?['salt'] ?? 'unknown',
            ),
            traces: _normalizeTags(productData['traces_tags'] ?? []),
          );

          return (basicModel, detailedModel);
        }
      }

      return (null, null);
    } catch (e) {
      print('Error fetching product: $e');
      rethrow;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class NutrientLevels {
  final String fat;
  final String saturatedFat;
  final String sugars;
  final String salt;

  NutrientLevels({
    required this.fat,
    required this.saturatedFat,
    required this.sugars,
    required this.salt,
  });
}
