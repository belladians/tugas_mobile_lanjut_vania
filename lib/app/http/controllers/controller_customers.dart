import 'dart:io';
import 'package:tugas_vania/app/models/tabel-customers.dart';
import 'package:tugas_vania/common/response.dart';
import 'package:vania/vania.dart';

class CustomersController extends Controller {
  Future<Response> index() async {
    try {
      final customers = await Customers().query().get();
      return JsonResponse.send(
        message: 'Customer list',
        data: customers,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> store(Request request) async {
    try {
      validateRequestBody(request);

      // Check duplicate phone number
      final duplicatePhone = await Customers()
          .query()
          .where('cust_telp', '=', request.body['cust_telp'])
          .first();
      if (duplicatePhone != null) {
        return JsonResponse.send(
          message: 'Conflict unique constraint',
          errors: {
            'cust_telp': 'Nomor telepon telah digunakan',
          },
          status: HttpStatus.conflict,
        );
      }

      // Insert data customer
      final customer = await Customers().query().insertGetId(request.body).then(
        (insertedId) async {
          return await Customers()
              .query()
              .where('cust_id', '=', insertedId)
              .first();
        },
      );

      return JsonResponse.send(
        message: 'Customer berhasil ditambahkan',
        data: customer,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> show(int id) async {
    try {
      final customer = await Customers().query().where({'cust_id': id}).first();
      if (customer == null) {
        return JsonResponse.notFound("Customer dengan ID $id tidak ditemukan");
      }

      return JsonResponse.send(
        message: 'Customer detail',
        data: customer,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> update(Request request, int id) async {
    try {
      validateRequestBody(request, isUpdate: true);

      // Check eksistensi data customer berdasarkan id
      final customer = await Customers().query().where({'cust_id': id}).first();
      if (customer == null) {
        return JsonResponse.notFound("Customer dengan ID $id tidak ditemukan");
      }

      // Check duplicate phone number
      final duplicatePhone = await Customers()
          .query()
          .where('cust_telp', '=', request.body['cust_telp'])
          .first();
      if (duplicatePhone != null && duplicatePhone['cust_id'] != id) {
        return JsonResponse.send(
          message: 'Conflict unique constraint',
          errors: {
            'cust_telp': 'Nomor telepon telah digunakan',
          },
          status: HttpStatus.conflict,
        );
      }

      // Update data customer
      await Customers().query().where({'cust_id': id}).update(request.body);
      final updatedCustomer =
          await Customers().query().where({'cust_id': id}).first();

      return JsonResponse.send(
        message: 'Customer berhasil diupdate',
        data: updatedCustomer,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> destroy(int id) async {
    try {
      // Check eksistensi data customer
      final customer = await Customers().query().where({'cust_id': id}).first();
      if (customer == null) {
        return JsonResponse.notFound("Customer dengan ID $id tidak ditemukan");
      }

      // Hapus data customer
      await Customers().query().where({'cust_id': id}).delete();

      return JsonResponse.send(message: 'Customer berhasil dihapus');
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  // JSON Request body validator untuk method store dan update
  // Aturan validasi dibedakan antara store dan update
  void validateRequestBody(Request request, {bool isUpdate = false}) {
    final nonRequiredMessages = {
      'cust_name.max_length': 'Nama tidak boleh lebih dari 50 karakter',
      'cust_address.max_length': 'Alamat tidak boleh lebih dari 50 karakter',
      'cust_city.max_length': 'Kota tidak boleh lebih dari 20 karakter',
      'cust_state.max_length': 'State tidak boleh lebih dari 5 karakter',
      'cust_zip.max_length': 'Zip tidak boleh lebih dari 10 karakter',
      'cust_country.max_length': 'Country tidak boleh lebih dari 25 karakter',
      'cust_telp.max_length': 'Telp tidak boleh lebih dari 15 karakter',
    };

    isUpdate
        ? request.validate({
            'cust_name': 'max_length:50',
            'cust_address': 'max_length:50',
            'cust_city': 'max_length:20',
            'cust_state': 'max_length:5',
            'cust_zip': 'max_length:10',
            'cust_country': 'max_length:25',
            'cust_telp': 'max_length:15',
          }, nonRequiredMessages)
        : request.validate({
            'cust_name': 'required|max_length:50',
            'cust_address': 'required|max_length:50',
            'cust_city': 'required|max_length:20',
            'cust_state': 'required|max_length:5',
            'cust_zip': 'required|max_length:10',
            'cust_country': 'required|max_length:25',
            'cust_telp': 'required|max_length:15',
          }, {
            'cust_name.required': 'Nama tidak boleh kosong',
            'cust_address.required': 'Alamat tidak boleh kosong',
            'cust_city.required': 'Kota tidak boleh kosong',
            'cust_state.required': 'State tidak boleh kosong',
            'cust_zip.required': 'Zip tidak boleh kosong',
            'cust_country.required': 'Country tidak boleh kosong',
            'cust_telp.required': 'Telp tidak boleh kosong',
            ...nonRequiredMessages
          });
  }
}

final CustomersController customersController = CustomersController();
