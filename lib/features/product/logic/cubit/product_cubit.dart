import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repo/product_repository.dart';
import '../../data/models/product_model.dart';
import '../../data/models/detailed_product_model.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit(this._repository) : super(ProductInitial());

  Future<void> scanProduct(String barcode) async {
    emit(ProductLoading());
    try {
      final (basicProduct, detailedProduct) =
          await _repository.getProductByBarcode(barcode);

      if (basicProduct != null && detailedProduct != null) {
        emit(ProductLoaded(
          basicProduct: basicProduct,
          detailedProduct: detailedProduct,
        ));
      } else {
        emit(const ProductError('Product not found'));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void reset() {
    emit(ProductInitial());
  }
}
