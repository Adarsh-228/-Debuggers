import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String barcode;
  final String name;
  final String? imageUrl;
  final String? nutriScore;
  final Map<String, dynamic>? nutrients;
  final String? brands;
  final String? quantity;
  final String? ingredients;
  final List<String>? allergens;
  final String? servingSize;
  final String? categories;
  final String? packaging;
  final String? origins;
  final String? labels;
  final String? stores;
  final String? countries;

  const ProductModel({
    required this.barcode,
    required this.name,
    this.imageUrl,
    this.nutriScore,
    this.nutrients,
    this.brands,
    this.quantity,
    this.ingredients,
    this.allergens,
    this.servingSize,
    this.categories,
    this.packaging,
    this.origins,
    this.labels,
    this.stores,
    this.countries,
  });

  @override
  List<Object?> get props => [
        barcode,
        name,
        imageUrl ?? '',
        nutriScore ?? '',
        nutrients ?? {},
        brands ?? '',
        quantity ?? '',
        ingredients ?? '',
        allergens ?? [],
        servingSize ?? '',
        categories ?? '',
        packaging ?? '',
        origins ?? '',
        labels ?? '',
        stores ?? '',
        countries ?? '',
      ];
}
