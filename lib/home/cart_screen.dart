import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastcampus_market_02/home/widgets/seller_widget.dart';
import 'package:fastcampus_market_02/model/product.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final String uid;

  const CartScreen({
    super.key,
    required this.uid,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 장바구니 상품 정보 가져오기 (Stream 방식)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCartItems() {
    return FirebaseFirestore.instance
        .collection('cart')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('timestamp')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
                stream: streamCartItems(),
                builder: (context, snapshot) {
                  // 데이터가 있을 경우
                  if (snapshot.hasData) {
                    List<Cart> items = snapshot.data?.docs.map((e) {
                          final foo = Cart.fromJson(e.data());
                          return foo.copyWith(cartDocId: e.id);
                        }).toList() ??
                        [];
                    return ListView.separated(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _cartItem(item);
                      },
                      separatorBuilder: (context, _) => const Divider(),
                    );
                  }
                  // 데이터가 없을 경우
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }),
          ),
          const Divider(),
          _summeryWidget(),
          _orderButton(),
        ],
      ),
    );
  }

  Widget _cartItem(Cart item) {
    // 상품 가격 계산
    num price = (item.product?.isSale ?? false)
        ? item.product!.price! *
            (item.product!.saleRate! / 100) *
            (item.count ?? 1)
        : item.product!.price! * (item.count ?? 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(
                  item.product?.imgUrl ?? '',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.product?.title ?? ''),
                      IconButton(
                        onPressed: () {
                          // async ~ await 방법으로 할 수 있지만 then ~ 으로 비동기 안쓰고도 가능
                          FirebaseFirestore db = FirebaseFirestore.instance;
                          CollectionReference<Map<String, dynamic>> ref = db.collection('cart');
                          DocumentReference<Map<String, dynamic>> doc = ref.doc('${item.cartDocId}');
                          doc.get().then((DocumentSnapshot<Map<String, dynamic>> value) {
                            value.reference.delete();
                          });
                        },
                        icon: const Icon(
                          Icons.delete,
                        ),
                      ),
                    ],
                  ),
                  Text('${price.toStringAsFixed(0)}원'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          int count = item.count ?? 1;
                          count--;
                          if (count <= 1) {
                            count = 1;
                          }
                          FirebaseFirestore.instance
                              .collection('cart')
                              .doc('${item.cartDocId}')
                              .update({'count': count});
                        },
                        icon: const Icon(
                          Icons.remove_circle_outline,
                        ),
                      ),
                      Text('${item.count}'),
                      IconButton(
                        onPressed: () {
                          int count = item.count ?? 1;
                          count++;
                          if (count >= 99) {
                            count = 99;
                          }
                          FirebaseFirestore.instance
                              .collection('cart')
                              .doc('${item.cartDocId}')
                              .update({'count': count});
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Summery Widget
  Widget _summeryWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '합계',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          StreamBuilder(
              stream: streamCartItems(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Cart> items = snapshot.data?.docs
                          .map((QueryDocumentSnapshot<Map<String, dynamic>> e) {
                        final Cart foo = Cart.fromJson(e.data());
                        return foo.copyWith(cartDocId: e.id);
                      }).toList() ??
                      [];

                  double totalPrice = 0;
                  for (var element in items) {
                    if (element.product?.isSale ?? false) {
                      totalPrice += (element.product!.price! *
                              element.product!.saleRate! /
                              100) *
                          (element.count ?? 1);
                    } else {
                      totalPrice +=
                          element.product!.price! * (element.count ?? 1);
                    }
                  }
                  return Text(
                    '${totalPrice.toStringAsFixed(0)}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }),
        ],
      ),
    );
  }

  Widget _orderButton() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.red[100],
      ),
      child: const Center(
        child: Text(
          '배달 주문',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
