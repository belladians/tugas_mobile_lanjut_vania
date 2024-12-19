import 'dart:io';
import 'package:tugas_vania/app/models/tabel-product_notes.dart';
import 'package:tugas_vania/app/models/tabel-products.dart';
import 'package:tugas_vania/app/models/tabel-vendors.dart';
import 'package:tugas_vania/common/response.dart';
import 'package:vania/vania.dart';

class ProductsController extends Controller {
  Future<Response> index() async {
    try {
      final products = await Products().query().get();

      return JsonResponse.send(
        message: 'Product List',
        data: products,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> store(Request request) async {
    try {
      validateRequestBody(request);

      // Check duplikasi nama produk
      final duplicateProductName = await Products()
          .query()
          .where("prod_name", "=", request.body['prod_name'])
          .first();
      if (duplicateProductName != null) {
        return JsonResponse.send(
          message: "Conflict unique constraint",
          errors: {
            'prod_name': 'Nama produk telah digunakan',
          },
          status: HttpStatus.conflict,
        );
      }

      // Check eksistensi data vendor berdasarkan vendor id
      final vendorId = request.body['vend_id'];
      final vendor =
          await Vendors().query().where('vend_id', '=', vendorId).first();
      if (vendor == null) {
        return JsonResponse.notFound(
            "Vendor dengan id $vendorId tidak ditemukan");
      }

      final product = await Products().query().insertGetId(request.body).then(
        (insertedId) async {
          return await Products()
              .query()
              .where('prod_id', '=', insertedId)
              .first();
        },
      );

      return JsonResponse.send(
        message: 'Produk berhasil ditambahkan',
        data: product,
        status: HttpStatus.created,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> show(int id) async {
    try {
      final product =
          await Products().query().where("prod_id", "=", id).first();
      if (product == null) {
        return JsonResponse.notFound("Product dengan ID $id tidak ditemukan");
      }

      final productNotes = await ProductNotes()
          .query()
          .select(['note_id', 'note_text', 'note_date'])
          .where('prod_id', '=', id)
          .get();

      product['prod_notes'] = productNotes;

      return JsonResponse.send(data: product);
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> update(Request request, int id) async {
    try {
      validateRequestBody(request, isUpdate: true);

      // Check duplikasi nama produk
      final existsProductName = await Products()
          .query()
          .where("prod_name", "=", request.body['prod_name'])
          .first();
      if (existsProductName != null && existsProductName['prod_id'] != id) {
        return JsonResponse.send(
          message: "Conflict unique constraint",
          errors: {
            'prod_name': 'Nama produk telah digunakan',
          },
          status: HttpStatus.conflict,
        );
      }

      // Check eksistensi data product berdasarkan id
      final product =
          await Products().query().where("prod_id", "=", id).first();
      if (product == null) {
        return JsonResponse.notFound("Product tidak ditemukan");
      }

      // Update data product
      await Products().query().where("prod_id", "=", id).update(request.body);
      final updatedProduct =
          await Products().query().where("prod_id", "=", id).first();

      return JsonResponse.send(
        message: "Product Updated",
        data: updatedProduct,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> destroy(int id) async {
    try {
      // Check product
      final product =
          await Products().query().where("prod_id", "=", id).first();
      if (product == null) {
        return JsonResponse.notFound("Product tidak ditemukan");
      }

      await Products().query().where("prod_id", "=", id).delete();

      return JsonResponse.send(message: "Product deleted");
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> storeNote(Request request, int productId) async {
    try {
      request.validate({
        'note_text': 'required|string',
      }, {
        'note_text.required': "Catatan tidak boleh kosong",
        'note_text.string': "Catatan harus bertipe data String"
      });

      // Check eksistensi data product berdasarkan productId
      final product =
          await Products().query().where('prod_id', '=', productId).first();
      if (product == null) {
        return JsonResponse.notFound(
            "Product dengan ID $productId tidak ditemukan");
      }

      final note = await ProductNotes().query().insertGetId({
        'prod_id': productId,
        'note_text': request.body['note_text'],
        'note_date': DateTime.now().toIso8601String(),
      }).then(
        (insertedId) async {
          return await ProductNotes()
              .query()
              .where('note_id', '=', insertedId)
              .first();
        },
      );

      return JsonResponse.send(
        message: 'Product note created',
        data: note,
        status: HttpStatus.created,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> updateNote(
      Request request, int productId, int noteId) async {
    try {
      request.validate({
        'note_text': 'required|string',
      }, {
        'note_text.required': "Catatan tidak boleh kosong",
        'note_text.string': "Catatan harus bertipe data String"
      });

      // Check data product dan product note
      final product =
          await Products().query().where("prod_id", "=", productId).first();
      if (product == null) {
        return JsonResponse.notFound(
            "Product dengan ID $productId tidak ditemukan");
      }

      final productNote =
          await ProductNotes().query().where('note_id', '=', noteId).first();
      if (productNote == null) {
        return JsonResponse.notFound(
            "Product Note dengan ID $noteId tidak ditemukan");
      }

      // Update data note product
      await ProductNotes().query().where('note_id', '=', noteId).update({
        'note_text': request.body['note_text'],
        'note_date': DateTime.now().toIso8601String(),
      });

      final updatedNote =
          await ProductNotes().query().where('note_id', '=', noteId).first();

      return JsonResponse.send(
        message: "Product note updated",
        data: updatedNote,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> deleteNote(
      Request request, int productId, int noteId) async {
    try {
      // Check data product dan product note
      final product =
          await Products().query().where("prod_id", "=", productId).first();
      if (product == null) {
        return JsonResponse.notFound(
            "Product dengan ID $productId tidak ditemukan");
      }

      final productNote =
          await ProductNotes().query().where('note_id', '=', noteId).first();
      if (productNote == null) {
        return JsonResponse.notFound(
            "Product Note dengan ID $noteId tidak ditemukan");
      }

      // Hapus data product note
      await ProductNotes().query().where('note_id', '=', noteId).delete();

      return JsonResponse.send(
        message: "Product note deleted",
        data: null,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  // JSON Request body validator untuk method store dan update
  // Aturan validasi dibedakan antara store dan update
  void validateRequestBody(Request req, {bool isUpdate = false}) {
    const nonRequiredMessages = {
      'prod_price.integer': 'Harga produk harus berupa angka',
      'prod_name.max_length': 'Nama produk tidak boleh lebih dari 25 karakter',
      'prod_name.string': 'Nama produk harus berupa string',
      'prod_desc.string': 'Deskripsi produk harus berupa string',
    };

    isUpdate
        ? req.validate(
            {
              'prod_name': 'string|max_length:25',
              'prod_price': 'integer',
              'prod_desc': 'string',
            },
            nonRequiredMessages,
          )
        : req.validate(
            {
              'vend_id': 'required|integer',
              'prod_name': 'required|string|max_length:25',
              'prod_price': 'required|integer',
              'prod_desc': 'required|string',
            },
            {
              'vend_id.integer': 'Vendor ID harus berupa angka',
              'vend_id.required': 'ID Vendor harus diisi',
              'prod_name.required': 'Nama produk harus diisi',
              'prod_price.required': 'Harga produk harus diisi',
              'prod_desc.required': 'Deskripsi produk harus diisi',
              ...nonRequiredMessages
            },
          );
  }
}

final ProductsController productsController = ProductsController();
