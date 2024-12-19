import 'package:tugas_vania/app/models/tabel-users.dart';

Map<String, dynamic> authConfig = {
  'guards': {
    'default': {
      'provider': Users(),
    }
  }
};
