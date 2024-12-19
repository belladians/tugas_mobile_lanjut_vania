import 'dart:io';
import 'package:tugas_vania/app/models/tabel-vendors.dart';
import 'package:tugas_vania/common/response.dart';
import 'package:vania/vania.dart';

class VendorsController extends Controller {
  Future<Response> index() async {
    try {
      final vendors = await Vendors().query().get();

      return JsonResponse.send(
        message: 'Vendor List',
        data: vendors,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> store(Request req) async {
    try {
      validateRequestBody(req);

      // Check nama vendor apakah telah digunakan.
      final duplicateName = await Vendors()
          .query()
          .where('vend_name', '=', req.body['vend_name'])
          .first();
      if (duplicateName != null) {
        return JsonResponse.send(
          message: 'Conflict unique constraint',
          errors: {
            'vend_name': "Nama vendor telah digunakan",
          },
          status: HttpStatus.conflict,
        );
      }

      // Insert data vendor
      final insertedId = await Vendors().query().insertGetId(req.body);
      final vendor =
          await Vendors().query().where('vend_id', "=", insertedId).first();

      return JsonResponse.send(
        message: 'Vendor Created',
        data: vendor,
        status: HttpStatus.created,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> show(int id) async {
    try {
      // Check eksistensi data vendor berdasarkan id
      final vendor = await Vendors().query().where('vend_id', "=", id).first();
      if (vendor == null) {
        return JsonResponse.notFound("Vendor dengan ID $id tidak ditemukan");
      }

      return JsonResponse.send(
        message: 'Vendor Detail',
        data: vendor,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> update(Request request, int id) async {
    try {
      validateRequestBody(request, isUpdate: true);

      if (request.body.isEmpty) {
        return JsonResponse.send(
          errors: {
            'body': 'Minimal satu field yang akan diupdate',
          },
          status: HttpStatus.badRequest,
        );
      }

      // Check nama vendor apakah telah digunakan.
      if (request.body.containsKey('vend_name')) {
        final duplicateName = await Vendors()
            .query()
            .where('vend_name', '=', request.body['vend_name'])
            .first();
        if (duplicateName != null && duplicateName['vend_id'] != id) {
          return JsonResponse.send(
            errors: {
              'vend_name': "Nama vendor telah digunakan",
            },
            status: HttpStatus.conflict,
          );
        }
      }

      // Check eksistensi data vendor berdasarkan id
      final vendor = await Vendors().query().where('vend_id', "=", id).first();
      if (vendor == null) {
        return JsonResponse.notFound("Vendor dengan ID $id tidak ditemukan");
      }

      // Update data vendor
      await Vendors().query().where('vend_id', "=", id).update(request.body);
      final updatedVendor =
          await Vendors().query().where('vend_id', "=", id).first();

      return JsonResponse.send(
        message: 'Vendor Updated',
        data: updatedVendor,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> destroy(int id) async {
    try {
      // Check eksistensi data vendor berdasarkan id
      final vendor = await Vendors().query().where('vend_id', "=", id).first();
      if (vendor == null) {
        return JsonResponse.notFound("Vendor dengan ID $id tidak ditemukan");
      }

      // Hapus data vendor
      await Vendors().query().where('vend_id', "=", id).delete();

      return JsonResponse.send(message: "Vendor Deleted");
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  // JSON Request body validator untuk method store dan update
  // Aturan validasi dibedakan antara store dan update
  void validateRequestBody(Request req, {bool isUpdate = false}) {
    final nonRequiredMessages = {
      'vend_name.max_length': 'Nama vendor tidak boleh lebih dari 50 karakter',
      'vend_state.max_length': 'State vendor tidak boleh lebih dari 5 karakter',
      'vend_zip.max_length': 'Zip vendor tidak boleh lebih dari 7 karakter',
      'vend_country.max_length':
          'Country vendor tidak boleh lebih dari 25 karakter',
    };
    isUpdate
        ? req.validate(
            {
              'vend_name': 'max_length:50',
              'vend_address': '',
              'vend_kota': '',
              'vend_state': 'max_length:5',
              'vend_zip': 'max_length:7',
              'vend_country': 'max_length:25',
            },
            nonRequiredMessages,
          )
        : req.validate(
            {
              'vend_name': 'required|max_length:50',
              'vend_address': 'required',
              'vend_kota': 'required',
              'vend_state': 'required|max_length:5',
              'vend_zip': 'required|max_length:7',
              'vend_country': 'required|max_length:25',
            },
            {
              'vend_name.required': 'Nama vendor tidak boleh kosong',
              'vend_kota.required': 'Kota vendor tidak boleh kosong',
              'vend_state.required': 'State vendor tidak boleh kosong',
              'vend_zip.required': 'Zip vendor tidak boleh kosong',
              'vend_country.required': 'Country vendor tidak boleh kosong',
              'vend_address.required': 'Alamat vendor tidak boleh kosong',
              ...nonRequiredMessages
            },
          );
  }
}

final VendorsController vendorsController = VendorsController();
