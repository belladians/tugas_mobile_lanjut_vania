import 'dart:io';
import 'package:vania/vania.dart';
import 'create_vendors.dart';
import 'create_users.dart';
import 'create_token.dart';
import 'create_customers.dart';
import 'create_orders.dart';
import 'create_order_items.dart';
import 'create_products.dart';
import 'create_product_notes.dart';

void main(List<String> args) async {
  await MigrationConnection().setup();
  if (args.isNotEmpty && args.first.toLowerCase() == "migrate:fresh") {
    await Migrate().dropTables();
  } else {
    await Migrate().registry();
  }
  await MigrationConnection().closeConnection();
  exit(0);
}

class Migrate {
  registry() async {
		 await CreateVendors().up();
     await CreateProducts().up();
		 await CreateUsers().up();
		 await CreateToken().up();
		 await CreateCustomers().up();
		 await CreateOrders().up();
		 await CreateOrderItems().up();
		 await CreateProductNotes().up();
	}

  dropTables() async {
		 await CreateProductNotes().down();
		 await CreateProducts().down();
		 await CreateOrderItems().down();
		 await CreateOrders().down();
		 await CreateCustomers().down();
		 await CreateToken().down();
		 await CreateUsers().down();
		 await CreateVendors().down();
	 }
}
