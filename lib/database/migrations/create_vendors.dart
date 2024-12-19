import 'package:vania/vania.dart';

class CreateVendors extends Migration {
  @override
  Future<void> up() async {
    super.up();
    await createTableNotExists('vendors', () {
      char("vend_id", length: 5);
      primary("vend_id");
      char("vend_name", length: 50);
      text("vend_address");
      text("vend_city");
      char("vend_state", length: 5);
      char("vend_zip", length: 7);
      char("vend_country", length: 25);
    });
  }

  @override
  Future<void> down() async {
    super.down();
    await dropIfExists('vendors');
  }
}
