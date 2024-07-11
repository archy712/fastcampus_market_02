import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastcampus_market_02/model/product.dart';
import 'package:flutter/material.dart';

// products 컬렉션에서 데이터 가져오기 (Future 방식)
Future<List<Product>> fetchProducts() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final QuerySnapshot<Map<String, dynamic>> resp =
      await db.collection('products').orderBy('timestamp').get();
  List<Product> items = [];
  for (QueryDocumentSnapshot<Map<String, dynamic>> doc in resp.docs) {
    final Product item = Product.fromJson(doc.data());
    //final Product realItem = item.copyWith(docId: doc.id);
    items.add(item);
  }
  return items;
}

// Stream 방식
Stream<QuerySnapshot> streamProducts(String query) {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  if (query.isNotEmpty) {
    return db
        .collection('products')
        .orderBy('title')
        .startAt([query]).endAt(['${query}uf8ff']).snapshots();
  }

  return db.collection('products').orderBy('timestamp').snapshots();
}

class SellerWidget extends StatefulWidget {
  const SellerWidget({super.key});

  @override
  State<SellerWidget> createState() => _SellerWidgetState();
}

class _SellerWidgetState extends State<SellerWidget> {
  TextEditingController searchController = TextEditingController();

  // 상품 수정
  Future<void> updateProduct(Product? item) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final CollectionReference<Map<String, dynamic>> ref =
        db.collection('products');
    await ref.doc(item?.docId).update(
          item!
              .copyWith(
                title: 'milk',
                price: 1000,
                stock: 10,
                isSale: false,
              )
              .toJson(),
        );
  }

  // 상품 삭제
  Future<void> deleteProduct(Product? item) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection('products').doc(item?.docId).delete();

    // products 컬렉션 데이터의 category 컬렉션 얻기
    final QuerySnapshot<Map<String, dynamic>> productCategory = await db
        .collection('products')
        .doc(item?.docId)
        .collection('category')
        .get();
    final QueryDocumentSnapshot<Map<String, dynamic>> foo = productCategory.docs.first;
    final dynamic categoryId = foo.data()['docId'];
    final bar = await db
        .collection('category')
        .doc(categoryId)
        .collection('products')
        .where(
          'docId',
          isEqualTo: item?.docId,
        ).get();
    // 중복이 있으면 삭제
    for (QueryDocumentSnapshot<Map<String, dynamic>> element in bar.docs) {
      element.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBar(
            controller: searchController,
            leading: const Icon(Icons.search),
            onChanged: (s) {
              setState(() {});
            },
            hintText: '상품명 입력',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          // 카테고리 버튼 바
          _categoryButtonBarWidget(context),
          _productTitleWidget(),
          Expanded(
            child: StreamBuilder(
                stream: streamProducts(searchController.text),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final items = snapshot.data!.docs
                        .map((e) =>
                            Product.fromJson(e.data() as Map<String, dynamic>)
                                .copyWith(
                              docId: e.id,
                            ))
                        .toList();

                    return _productListWidget(context, items);
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }),
          ),
        ],
      ),
    );
  }

  // 카테고리 버튼바
  ButtonBar _categoryButtonBarWidget(BuildContext context) {
    return ButtonBar(
      children: [
        ElevatedButton(
          onPressed: () async {
            List<String> categories = [
              '정육',
              '과일',
              '과자',
              '아이스크림',
              '유제품',
              '라면',
              '생수',
              '빵/쿠키',
            ];

            // 방법 1 : 직접 중복 제거 후 등록
            final CollectionReference ref =
                FirebaseFirestore.instance.collection('category');
            final QuerySnapshot tmp = await ref.get();

            // 중복 제거
            for (QueryDocumentSnapshot element in tmp.docs) {
              await element.reference.delete();
            }

            for (String element in categories) {
              await ref.add({'title': element});
            }

            // 방법 2 : 기존 함수 사용 방법
            // for (int i = 0; i < categories.length; i++) {
            //   await addCategories(categories[i]);
            // }
            //

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('카테고리 일괄등록 성공'),
                ),
              );
            }
          },
          child: const Text('카테고리 일괄등록'),
        ),
        ElevatedButton(
          onPressed: () {
            TextEditingController tec = TextEditingController();
            showAdaptiveDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: TextFormField(
                  controller: tec,
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      if (tec.text.isNotEmpty) {
                        await addCategories(tec.text.trim());
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    child: const Text('등록'),
                  ),
                ],
              ),
            );
          },
          child: const Text('카테고리 등록'),
        ),
      ],
    );
  }

  Future addCategories(String title) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final CollectionReference ref = db.collection('category');
    await ref.add({'title': title});
  }

  // 상품목록 타이틀
  Padding _productTitleWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        '상품 목록',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // 상품 리스트 목록
  ListView _productListWidget(BuildContext context, List<Product> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          child: _productItemWidget(item),
        );
      },
    );
  }

  // 상품 아이템 위젯
  Widget _productItemWidget(Product item) {
    return GestureDetector(
      onTap: () {
        log(item.docId.toString());
      },
      child: Row(
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.imgUrl ??
                    'https://sitem.ssgcdn.com/79/48/87/item/1000039874879_i2_580.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title ?? '제품명',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            child: Text('리뷰'),
                          ),
                          PopupMenuItem(
                            child: const Text('수정'),
                            onTap: () async => updateProduct(item),
                          ),
                          PopupMenuItem(
                            child: const Text('삭제'),
                            onTap: () async => deleteProduct(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text('${item.price}원'),
                  Text(switch (item.isSale) {
                    true => '할인 중',
                    false => '할인 없음',
                    _ => '??'
                  }),
                  Text('재고수량 : ${item.stock} 개'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
