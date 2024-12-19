import 'package:vania/vania.dart';

class CreateProductNotes extends Migration {
  @override
  Future<void> up() async {
    super.up();
    await createTableNotExists('product_notes', () {
      char("note_id", length: 5);
      primary("note_id");
      char("prod_id", length: 10);
      date("note_date");
      text("note_text");
    });
  }

  @override
  Future<void> down() async {
    super.down();
    await dropIfExists('product_notes');
  }
}
