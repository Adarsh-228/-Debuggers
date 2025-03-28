import 'package:equatable/equatable.dart';
import 'package:healthcompanion/features/product/data/repo/product_repository.dart';

class DetailedProductModel extends Equatable {
  final String barcode;
  final String name;
  final String? imageUrl;
  final String? nutriScore;
  final NutrimentsModel nutrients;
  final String? brands;
  final String? quantity;
  final List<String> ingredients;
  final List<String> allergens;
  final String? servingSize;
  final List<String> categories;
  final List<String> packaging;
  final String? origins;
  final List<String> labels;
  final String? stores;
  final List<String> countries;
  final String? novaGroup;
  final String? ecoscore;
  final NutrientLevels nutrientLevels;
  final List<String> traces;

  const DetailedProductModel({
    required this.barcode,
    required this.name,
    this.imageUrl,
    this.nutriScore,
    required this.nutrients,
    this.brands,
    this.quantity,
    required this.ingredients,
    required this.allergens,
    this.servingSize,
    required this.categories,
    required this.packaging,
    this.origins,
    required this.labels,
    this.stores,
    required this.countries,
    this.novaGroup,
    this.ecoscore,
    required this.nutrientLevels,
    required this.traces,
  });

  @override
  List<Object?> get props => [
        barcode,
        name,
        imageUrl,
        nutriScore,
        nutrients,
        brands,
        quantity,
        ingredients,
        allergens,
        servingSize,
        categories,
        packaging,
        origins,
        labels,
        stores,
        countries,
        novaGroup,
        ecoscore,
        nutrientLevels,
        traces,
      ];
}

class NutrimentsModel extends Equatable {
  final double energy;
  final double proteins;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugars;
  final double salt;
  final double saturatedFat;
  final double? calcium;
  final double? iron;
  final double? vitaminA;
  final double? vitaminC;
  final double? transFat;
  final double? cholesterol;
  final double? sodium;

  const NutrimentsModel({
    required this.energy,
    required this.proteins,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugars,
    required this.salt,
    required this.saturatedFat,
    this.calcium,
    this.iron,
    this.vitaminA,
    this.vitaminC,
    this.transFat,
    this.cholesterol,
    this.sodium,
  });

  @override
  List<Object?> get props => [
        energy,
        proteins,
        carbohydrates,
        fat,
        fiber,
        sugars,
        salt,
        saturatedFat,
        calcium,
        iron,
        vitaminA,
        vitaminC,
        transFat,
        cholesterol,
        sodium,
      ];
}
