part of 'product_cubit.dart';

abstract class ProductState {
  const ProductState();
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final ProductModel basicProduct;
  final DetailedProductModel detailedProduct;

  const ProductLoaded({
    required this.basicProduct,
    required this.detailedProduct,
  });
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
}
