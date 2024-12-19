import 'package:vania/vania.dart';

class CreateCustomers extends Migration {
  @override
  Future<void> up() async {
    super.up();
    await createTableNotExists('customers', () {
      char("cust_id", length: 5);
      primary("cust_id");
      char("cust_name", length: 50);
      char("cust_address", length: 50);
      char("cust_city", length: 20);
      char("cust_state", length: 10);
      char("cust_zip", length: 10);
      char("cust_country", length: 20);
      char("cust_telp");
    });
  }

  @override
  Future<void> down() async {
    super.down();
    await dropIfExists('customers');
  }
}
