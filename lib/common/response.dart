import 'dart:io';

// ignore: implementation_imports
import 'package:vania/src/exception/validation_exception.dart';
// ignore: implementation_imports
import 'package:vania/src/exception/unauthenticated.dart';
import 'package:vania/vania.dart';

// Helper class untuk mengirim response JSON
class JsonResponse {
  static Response send({
    String? message,
    dynamic data,
    dynamic errors,
    int status = HttpStatus.ok,
  }) {
    return Response.json(
      {
        'message': message,
        'data': data,
        'errors': errors,
      },
      status,
    );
  }

  static Response notFound(String message) {
    return JsonResponse.send(
      message: message,
      status: HttpStatus.notFound,
    );
  }

  static Response handleError(Object e) {
    print("Error: $e");
    if (e is ValidationException) {
      return JsonResponse.send(
        message: "Validation Error",
        errors: e.message,
        status: e.code,
      );
    } else if (e is Unauthenticated) {
      return JsonResponse.send(
        message: e.message,
        status: HttpStatus.unauthorized,
      );
    } else {
      return JsonResponse.send(
        message: 'Terjadi kesalahan, coba lagi beberapa saat',
        status: HttpStatus.internalServerError,
      );
    }
  }
}
