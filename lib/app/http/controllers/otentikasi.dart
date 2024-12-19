import 'dart:io';
import 'package:tugas_vania/app/models/tabel-users.dart';
import 'package:tugas_vania/common/response.dart';
import 'package:vania/vania.dart';

class AuthController extends Controller {
  Future<Response> register(Request req) async {
    try {
      req.validate({
        'name': 'required',
        'email': 'required|email',
        'password': 'required|min_length:6',
      }, {
        'name.required': 'Nama tidak boleh kosong',
        'email.required': 'Email tidak boleh kosong',
        'email.email': 'Email tidak valid',
        'password.required': 'Password tidak boleh kosong',
        'password.min_length': 'Password minimal 6 karakter',
      });

      // Check email conflict
      final existingUser =
          await Users().query().where('email', req.body['email']).first();
      if (existingUser != null) {
        return JsonResponse.send(
          message: 'Conflict unique constraint',
          errors: {
            'email': 'Email telah digunakan',
          },
          status: HttpStatus.conflict,
        );
      }

      // Hash password
      final hashedPassword = Hash().make(req.body['password']);

      // Insert user
      await Users().query().insert({
        'name': req.body['name'],
        'email': req.body['email'],
        'password': hashedPassword,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      });

      return JsonResponse.send(
        message: 'Registrasi berhasil',
        status: HttpStatus.created,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> login(Request req) async {
    try {
      req.validate({
        'email': 'required|email',
        'password': 'required',
      }, {
        'email.required': 'Email tidak boleh kosong',
        'email.email': 'Email tidak valid',
        'password.required': 'Password tidak boleh kosong',
      });

      final email = req.string('email');
      final password = req.string('password');

      // Find user by email
      final user = await Users().query().where('email', "=", email).first();
      if (user == null) {
        return JsonResponse.send(
          message: 'Periksa kembali kredensial Anda',
          status: HttpStatus.unauthorized,
        );
      }

      // Verifikasi password
      final passwordVerified = Hash().verify(password, user['password']);
      if (!passwordVerified) {
        return JsonResponse.send(
          message: 'Periksa kembali kredensial Anda',
          status: HttpStatus.unauthorized,
        );
      }

      // Generate access dan refresh token
      // Default expiry refresh token yang diisuekan oleh vania adalah 30 Hari
      final token = await Auth().login(user).createToken(
            expiresIn: const Duration(hours: 1), // Expiry access token 1 Jam
            withRefreshToken: true,
          );

      return JsonResponse.send(
        message: 'Login berhasil',
        data: token,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> logout(Request req) async {
    try {
      await Auth().deleteCurrentToken();
      return JsonResponse.send(message: 'Logout berhasil');
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> refreshToken(Request req) async {
    try {
      String? refreshToken =
          req.header('authorization')?.replaceFirst('Bearer ', '');
      if (refreshToken == null) {
        return JsonResponse.send(
          message: 'Refresh token not found',
          status: HttpStatus.unauthorized,
        );
      }

      // Generate access dan refresh token baru
      // Default expiry refresh token yang diisuekan oleh vania adalah 30 Hari
      // NOTE: This is weird, refreshing token should only refresh the access token, but this function also refreshes the refresh token XD.
      final newTokens = await Auth().createTokenByRefreshToken(
        refreshToken,
        expiresIn: const Duration(hours: 1), // Expiry access token 1 Jam
      );

      return JsonResponse.send(
        message: 'Token refreshed',
        data: newTokens,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }
}

final AuthController authController = AuthController();
