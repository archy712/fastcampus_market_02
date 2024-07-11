import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:fastcampus_market_02/model/category.dart';
import 'package:fastcampus_market_02/model/product.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  PageController pageController = PageController();
  int bannerIndex = 0;

  // 상단 타이틀 위젯
  Widget _titleWidget() {
    return Container(
      height: 140,
      //color: Colors.indigo,
      margin: const EdgeInsets.only(bottom: 8),
      child: PageView(
        controller: pageController,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/fastcampus_logo.png'),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/fastcampus_logo.png'),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/fastcampus_logo.png'),
          ),
        ],
        onPageChanged: (index) {
          setState(() {
            bannerIndex = index;
          });
        },
      ),
    );
  }

  // 카테고리 위젯
  Widget _categoryWidget() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '카테고리',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            // color: Colors.red,
            child: StreamBuilder(
              stream: streamCategories(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                  snapshot) {
                if (snapshot.hasData) {
                  categoryItems.clear();
                  final QuerySnapshot<Map<String, dynamic>>? categories =
                      snapshot.data;
                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                  docItems = categories?.docs ?? [];
                  for (QueryDocumentSnapshot<Map<String, dynamic>> doc
                  in docItems) {
                    categoryItems.add(
                      Category(
                        docId: doc.id,
                        title: doc.data()['title'],
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                    itemCount: categoryItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Category item = categoryItems[index];
                      return Column(
                        children: [
                          const CircleAvatar(radius: 24),
                          const SizedBox(height: 8),
                          Text(
                            item.title ?? '카테고리??',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 오늘의 특가 위젯
  Widget _saleWidget() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 특가',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('더보기'),
              ),
            ],
          ),
          SizedBox(
            height: 240,
            //color: Colors.orange,
            child: FutureBuilder(
                future: fetchSaleProducts(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Product>> snapshot) {
                  if (snapshot.hasData) {
                    List<Product> items = snapshot.data ?? [];
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        Product item = items[index];
                        return GestureDetector(
                          onTap: () {
                            context.go('/product', extra: item);
                            // 아래와 같은 방식으로도 사용 가능
                            // GoRouter.of(context).go('/product', extra: item);
                          },
                          child: _saleProductWidget(item),
                        );
                      },
                    );
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

  // Category 목록 가져오기
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCategories() {
    return FirebaseFirestore.instance.collection('category').snapshots();
  }

  List<Category> categoryItems = [];

  // 오늘의 특가 (FutureBuilder 방식 구현)
  Future<List<Product>> fetchSaleProducts() async {
    final CollectionReference<Map<String, dynamic>> dbRef =
        FirebaseFirestore.instance.collection('products');
    final QuerySnapshot<Map<String, dynamic>> saleItems =
        await dbRef.where('isSale', isEqualTo: true).orderBy('saleRate').get();
    List<Product> products = [];
    for (QueryDocumentSnapshot<Map<String, dynamic>> element
        in saleItems.docs) {
      Product item = Product.fromJson(element.data());
      Product copyItem = item.copyWith(docId: element.id);
      products.add(copyItem);
    }
    return products;
  }

  // 오늘의 특가 상품 위젯
  Column _saleProductWidget(Product item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: 160,
            margin:
            const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.imgUrl ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Text(
          item.title ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          '${item.price}원',
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
          ),
        ),
        Text(
            '${(item.price! * (item.saleRate! / 100)).toStringAsFixed(0)}원'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _titleWidget(),
          DotsIndicator(
            dotsCount: 3,
            position: bannerIndex,
          ),
          _categoryWidget(),
          _saleWidget(),
        ],
      ),
    );
  }
}
