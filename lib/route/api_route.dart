import 'package:tugas_vania/app/http/controllers/otentikasi.dart';
import 'package:tugas_vania/app/http/controllers/controller_customers.dart';
import 'package:tugas_vania/app/http/controllers/controller_orders.dart';
import 'package:tugas_vania/app/http/controllers/controller_products.dart';
import 'package:tugas_vania/app/http/controllers/controller_user.dart';
import 'package:tugas_vania/app/http/controllers/controller_vendors.dart';
import 'package:tugas_vania/app/http/middleware/authenticate.dart';
import 'package:vania/vania.dart';

class ApiRoute implements Route {
  @override
  void register() {
    Router.basePrefix('api');

// route untuk kelola akun
    Router.group(
      () {
        Router.post("/register", AuthController().register);
        Router.post("/login", AuthController().login);
        Router.delete("/logout", AuthController().logout).middleware(
          [AuthenticateMiddleware()],
        );
        Router.get("/data_saya", UserController().currentUser);
        Router.get("/refresh_token", AuthController().refreshToken);
      },
      prefix: "/akun",
    );


    // route vendor
    Router.group(
      () {
        Router.get("/", VendorsController().index);
        Router.post("/", VendorsController().store);
        Router.get("/{id}", VendorsController().show);
        Router.put("/{id}", VendorsController().update);
        Router.delete("/{id}", VendorsController().destroy);
      },
      prefix: "/vendors",
      middleware: [AuthenticateMiddleware()],
    );

    // route products
    Router.group(
      () {
        Router.get("/", ProductsController().index);
        Router.post("/", ProductsController().store);
        Router.get("/{id}", ProductsController().show);
        Router.put("/{id}", ProductsController().update);
        Router.delete("/{id}", ProductsController().destroy);
        Router.post("/{productId}/notes", ProductsController().storeNote);
        Router.put(
          "/{productId}/notes/{noteId}",
          ProductsController().updateNote,
        );
        Router.delete(
          "/{productId}/notes/{noteId}",
          ProductsController().deleteNote,
        );
      },
      prefix: "/products",
      middleware: [AuthenticateMiddleware()],
    );

    // route customers
    Router.group(
      () {
        Router.get("/", CustomersController().index);
        Router.post("/", CustomersController().store);
        Router.get("/{id}", CustomersController().show);
        Router.put("/{id}", CustomersController().update);
        Router.delete("/{id}", CustomersController().destroy);
      },
      prefix: "/customers",
      middleware: [AuthenticateMiddleware()],
    );

    // route orders
    Router.group(
      () {
        Router.get("/", OrdersController().index);
        Router.post("/", OrdersController().store);
        Router.get("/{orderNum}", OrdersController().show);
        Router.delete("/{orderNum}", OrdersController().destroy);
        Router.post("/{orderNum}/items", OrdersController().storeItem);
        Router.put(
          "/{orderNum}/items/{itemId}",
          OrdersController().updateItem,
        );
        Router.delete(
          "/{orderNum}/items/{itemId}",
          OrdersController().destroyItem,
        );
      },
      prefix: "/orders",
      middleware: [AuthenticateMiddleware()],
    );
  }
}
