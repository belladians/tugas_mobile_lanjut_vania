import 'dart:convert';
import 'package:tugas_vania/app/models/tabel-customers.dart';
import 'package:tugas_vania/app/models/tabel-order_items.dart';
import 'package:tugas_vania/app/models/tabel-orders.dart';
import 'package:tugas_vania/app/models/tabel-products.dart';
import 'package:tugas_vania/common/response.dart';
import 'package:vania/vania.dart';
import 'package:vania/src/exception/validation_exception.dart';

class OrdersController extends Controller {
  Future<Response> index() async {
    try {
      final orders = await Orders().query().get();
      return JsonResponse.send(message: "Order list", data: orders);
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> store(Request request) async {
    try {
      request.validate({
        'cust_id': 'required|integer',
      }, {
        'cust_id.integer': 'ID Customer harus berupa angka',
        'cust_id.required': 'ID Customer harus diisi',
      });
      _validateOrderItems(request);

      // Check data customer
      final customer = await Customers()
          .query()
          .where('cust_id', "=", request.body['cust_id'])
          .first();
      if (customer == null) {
        return JsonResponse.notFound(
          "Customer dengan ID ${request.body['cust_id']} tidak ditemukan",
        );
      }

      // Check data produk
      final productIdsSet = request.body['order_items']
          .map((item) => item['prod_id'])
          .cast<int>()
          .toSet() as Set<int>;
      final productResults = await Products()
          .query()
          .whereIn('prod_id', productIdsSet.toList())
          .get();

      // Check produk yang tidak ditemukan
      final notFoundProducts = productIdsSet
          .difference(
            productResults.map((product) => product['prod_id'] as int).toSet(),
          )
          .toList();

      if (notFoundProducts.isNotEmpty) {
        return JsonResponse.notFound(
          "Produk dengan ID $notFoundProducts tidak ditemukan",
        );
      }

      // Insert order dan order_items menggunakan koneksi transaction
      // Jika salah satu query gagal, maka transaksi akan di-rollback atau dibatalkan
      await connection?.transaction((con) async {
        final orderNum = await Orders().query().insertGetId({
          'order_date': DateTime.now(),
          'cust_id': request.body['cust_id'],
        });

        final orderItems = request.body['order_items']
            .map<Map<String, dynamic>>((item) => {
                  'order_num': orderNum,
                  'prod_id': item['prod_id'],
                  'quantity': item['quantity'],
                  'size': item['size'],
                })
            .toList();

        await OrderItems().query().insertMany(orderItems);
      });

      return JsonResponse.send(message: 'Order berhasil dibuat');
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> show(int orderNum) async {
    try {
      // Query order dengan join ke customers dan order_items
      // Menggunakan JSON_OBJECT dan JSON_ARRAYAGG untuk menggabungkan data order_items dalam single query
      final order = await Orders()
          .query()
          .selectRaw("""
              orders.order_num,
              orders.order_date,
              JSON_OBJECT(
                'cust_id', customers.cust_id,
                'cust_name', customers.cust_name,
                'cust_address', customers.cust_address,
                'cust_city', customers.cust_city,
                'cust_state', customers.cust_state,
                'cust_zip', customers.cust_zip,
                'cust_country', customers.cust_country
              ) AS customer,
              COALESCE(
                JSON_ARRAYAGG(
                  JSON_OBJECT(
                  'order_item_id', order_items.order_item_id,
                  'product', JSON_OBJECT(
                    'prod_id', products.prod_id,
                    'prod_name', products.prod_name,
                    'prod_price', products.prod_price,
                    'prod_desc', products.prod_desc,
                    'prod_vendor_id', products.vend_id
                  ),
                  'quantity', order_items.quantity,
                  'size', order_items.size
                  )
                ),
                JSON_ARRAY()
              ) AS order_items
              """)
          .join('customers', 'orders.cust_id', '=', 'customers.cust_id')
          .leftJoin(
              'order_items', 'orders.order_num', '=', 'order_items.order_num')
          .leftJoin('products', 'order_items.prod_id', '=', 'products.prod_id')
          .groupBy('orders.order_num')
          .groupBy('orders.cust_id')
          .where('orders.order_num', "=", orderNum)
          .first();

      if (order == null) {
        return JsonResponse.notFound(
          "Order dengan nomor $orderNum tidak ditemukan",
        );
      }

      // Parse data customer dari JSON string ke Map<String, dynamic>
      order['customer'] = jsonDecode(order['customer']);

      // Parse data order_items dari JSON string ke List<Map<String, dynamic>>
      order['order_items'] =
          List<Map<String, dynamic>>.from(jsonDecode(order['order_items']));

      return JsonResponse.send(message: "Order detail", data: order);
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> destroy(int orderNum) async {
    try {
      final order =
          await Orders().query().where('order_num', "=", orderNum).first();
      if (order == null) {
        return JsonResponse.notFound(
          "Order dengan nomor $orderNum tidak ditemukan",
        );
      }
      await Orders().query().where('order_num', "=", orderNum).delete();

      return JsonResponse.send(message: 'Order berhasil dihapus');
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> storeItem(Request request, int orderNum) async {
    try {
      // Validasi request
      request.validate({
        'prod_id': 'required|integer',
        'quantity': 'required|integer',
        'size': 'required|integer',
      }, {
        'prod_id.integer': 'ID Product harus berupa angka',
        'quantity.integer': 'Quantity harus berupa angka',
        'size.integer': 'Size harus berupa angka',
        'prod_id.required': 'ID Product harus diisi',
        'quantity.required': 'Quantity harus diisi',
        'size.required': 'Size harus diisi',
      });

      // Check order
      final order =
          await Orders().query().where('order_num', "=", orderNum).first();
      if (order == null) {
        return JsonResponse.notFound(
          "Order dengan nomor $orderNum tidak ditemukan",
        );
      }

      // Check product
      final product = await Products()
          .query()
          .where('prod_id', "=", request.body['prod_id'])
          .first();

      if (product == null) {
        return JsonResponse.notFound(
          "Product dengan ID ${request.body['prod_id']} tidak ditemukan",
        );
      }

      // Insert order item
      final orderItem = await OrderItems().query().insertGetId({
        'order_num': orderNum,
        'prod_id': request.body['prod_id'],
        'quantity': request.body['quantity'],
        'size': request.body['size'],
      }).then((insertedId) async {
        return await OrderItems()
            .query()
            .where('order_item_id', "=", insertedId)
            .first();
      });

      return JsonResponse.send(
        message: 'Order item berhasil ditambahkan',
        data: orderItem,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> updateItem(Request request, int orderNum, int itemId) async {
    try {
      // Validasi request
      request.validate({
        'prod_id': 'integer',
        'quantity': 'integer',
        'size': 'integer',
      }, {
        'prod_id.integer': 'ID Product harus berupa angka',
        'quantity.integer': 'Quantity harus berupa angka',
        'size.integer': 'Size harus berupa angka',
      });

      // Check data order dan order item
      final order =
          await Orders().query().where('order_num', "=", orderNum).first();
      if (order == null) {
        return JsonResponse.notFound(
          "Order dengan nomor $orderNum tidak ditemukan",
        );
      }
      final orderItem = await OrderItems()
          .query()
          .where('order_item_id', "=", itemId)
          .first();
      if (orderItem == null) {
        return JsonResponse.notFound(
          "Order item dengan ID $itemId tidak ditemukan",
        );
      }

      // Update order item
      await OrderItems()
          .query()
          .where('order_item_id', "=", itemId)
          .update(request.body);

      final updatedOrderItem = await OrderItems()
          .query()
          .where('order_item_id', "=", itemId)
          .first();

      return JsonResponse.send(
        message: 'Order item berhasil diupdate',
        data: updatedOrderItem,
      );
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  Future<Response> destroyItem(int orderNum, int itemId) async {
    try {
      // Check data order dan order item
      final order =
          await Orders().query().where('order_num', "=", orderNum).first();
      if (order == null) {
        return JsonResponse.notFound(
          "Order dengan nomor $orderNum tidak ditemukan",
        );
      }
      final orderItem = await OrderItems()
          .query()
          .where('order_item_id', "=", itemId)
          .first();

      if (orderItem == null) {
        return JsonResponse.notFound(
          "Order item dengan ID $itemId tidak ditemukan",
        );
      }

      await OrderItems().query().where('order_item_id', "=", itemId).delete();
      return JsonResponse.send(message: 'Order item berhasil dihapus');
    } catch (e) {
      return JsonResponse.handleError(e);
    }
  }

  // Custom validator untuk array order_items
  void _validateOrderItems(Request req) {
    final orderItems = req.body['order_items'];
    if (orderItems != null) {
      if (orderItems is! List) {
        throw ValidationException(
          message: {'order_items': 'Order items harus berupa array'},
        );
      }

      final errorMap = <String, String>{};
      for (int i = 0; i < orderItems.length; i++) {
        final item = orderItems[i];

        if (item['prod_id'] == null) {
          errorMap['order_items.$i.prod_id'] = 'ID Product harus diisi';
        } else if (item['prod_id'] is! int) {
          errorMap['order_items.$i.prod_id'] = 'ID Product harus berupa angka';
        }

        if (item['quantity'] == null) {
          errorMap['order_items.$i.quantity'] = 'Quantity harus diisi';
        } else if (item['quantity'] is! int) {
          errorMap['order_items.$i.quantity'] = 'Quantity harus berupa angka';
        }

        if (item['size'] == null) {
          errorMap['order_items.$i.size'] = 'Size harus diisi';
        } else if (item['size'] is! int) {
          errorMap['order_items.$i.size'] = 'Size harus berupa angka';
        }
      }

      if (errorMap.isNotEmpty) {
        throw ValidationException(message: errorMap);
      }
    } else {
      throw ValidationException(
        message: {'order_items': 'Order items harus diisi'},
      );
    }
  }
}

final OrdersController ordersController = OrdersController();
