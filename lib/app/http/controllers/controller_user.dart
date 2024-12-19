import 'dart:io';
import 'package:tugas_vania/common/response.dart';
import 'package:vania/vania.dart';

class UserController extends Controller {
  Future<Response> currentUser(Request req) async {
    try {
      final currUser = Auth().user();
      if (currUser == null) {
        return JsonResponse.send(
          message: "User not identified",
          status: HttpStatus.unauthorized,
        );
      }

      // Omit password dari Map
      currUser.remove('password');

      return JsonResponse.send(
        message: "User identified",
        data: currUser,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }
}

final UserController userController = UserController();
