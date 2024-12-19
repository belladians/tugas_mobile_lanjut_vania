import 'package:vania/vania.dart';

class CreateOrderItems extends Migration {
  @override
  Future<void> up() async {
    super.up();
    await createTableNotExists('order_items', () {
      integer("order_item", length: 11);
      primary("order_item");
      integer("order_num", length: 11);
      char("prod_id", length: 10);
      foreign("prod_id", "products", "prod_id", onDelete: "CASCADE");
      integer("quantity", length: 11);
      integer("size", length: 11);
    });
  }

  @override
  Future<void> down() async {
    super.down();
    await dropIfExists('order_items');
  }
}
