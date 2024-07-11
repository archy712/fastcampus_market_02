import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastcampus_market_02/home/cart_screen.dart';
import 'package:fastcampus_market_02/login/provider/login_provider.dart';
import 'package:fastcampus_market_02/main.dart';
import 'package:fastcampus_market_02/model/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title!),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 상단 상품 이미지
                  _productImage(context),

                  /// 중간 상품 정보
                  _productInfo(context),

                  /// 하단 상품 탭 정보
                  _tabInfo(context),
                ],
              ),
            ),
          ),

          /// 하단 장바구니 버튼
          _basketButton(context),
        ],
      ),
    );
  }

  /// 상단 상품 이미지
  Widget _productImage(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        //color: Colors.orange,
        image: DecorationImage(
          image: NetworkImage(
            widget.product.imgUrl ?? '',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (widget.product.isSale) {
              true => Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: const Text(
                    '할인중',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              _ => Container(),
            },
          ],
        ),
      ),
    );
  }

  /// 중간에 상품 상세 정보
  Widget _productInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.product.title ?? '기본 상품 제목',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              _popupReviewButton(context),
            ],
          ),
          const Text('제품 상세 정보'),
          Text(widget.product.description ?? '제품 상세 정보가 없습니다.'),
          Row(
            children: [
              Text(
                '${widget.product.price.toString()}원',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.star,
                color: Colors.orange,
              ),
              // TODO: 평점 처리
              const Text('4.5'),
            ],
          ),
        ],
      ),
    );
  }

  /// 중간 상세정보 : 팝업 리뷰 버튼
  Widget _popupReviewButton(BuildContext context) {
    return PopupMenuButton(itemBuilder: (context) {
      return [
        PopupMenuItem(
          child: const Text('리뷰 등록'),
          onTap: () {
            int reviewScore = 0;
            showDialog(
              context: context,
              // barrierDismissible : Dialog 제외한 다른 화면 터치 X
              barrierDismissible: false,
              builder: (context) {
                TextEditingController reviewController =
                    TextEditingController();
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('리뷰 등록'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: reviewController,
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (index) => IconButton(
                              onPressed: () {
                                setState(() => reviewScore = index);
                              },
                              icon: Icon(
                                Icons.star,
                                color: index <= reviewScore
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          '취소',
                        ),
                      ),
                      Consumer(builder: (context, ref, child) {
                        final user = ref.watch(userCredentialProvider);
                        return TextButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('products')
                                .doc('${widget.product.docId}')
                                .collection('reviews')
                                .add({
                              'uid': user?.user?.uid ?? '',
                              'email': user?.user?.email ?? '',
                              'review': reviewController.text.trim(),
                              'timestamp': Timestamp.now(),
                              'score': reviewScore + 1,
                            });
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text(
                            '등록',
                          ),
                        );
                      }),
                    ],
                  );
                });
              },
            );
          },
        ),
      ];
    });
  }

  /// 상품 탭 부분
  Widget _tabInfo(context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(
                text: '제품 상세',
              ),
              Tab(
                text: '리뷰',
              ),
            ],
          ),
          Container(
            height: 500,
            child: TabBarView(
              children: [
                Container(
                  child: Text('제품 상세'),
                ),
                StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .doc('${widget.product.docId}')
                        .collection('reviews')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final items = snapshot.data?.docs ?? [];
                        return ListView.separated(
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text('${items[index].data()['review']}'),
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(),
                          itemCount: items.length,
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 장바구니 버튼
  Widget _basketButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 현재 화면의 상품이 장바구니에 있는지 체크
        FirebaseFirestore db = FirebaseFirestore.instance;
        QuerySnapshot<Map<String, dynamic>> dupItems = await db
            .collection('cart')
            .where('uid', isEqualTo: userCredential?.user?.uid ?? '')
            .where('product.docId', isEqualTo: widget.product.docId)
            .get();

        // 장바구니에 해당 상품이 있다면 > 메시지 표시 (원래는 수량 추가 필요)
        if (dupItems.docs.isNotEmpty) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => const AlertDialog(
                content: Text('장바구니에 이미 등록되어 있는 상품입니다!'),
              ),
            );
          }
          return;
        }

        // 장바구니 상품 추가
        // 현재는 모델을 만들지 않았지만, 데이터 양이 많아지면 모델로 만드는게 좋다.
        // 또한, try ~ catch 처리로 하는게 좋다.
        // 나중에 소스 개선할 때는 위 2가지 사항 스스로 해 볼 것.
        await db.collection('cart').add({
          'uid': userCredential?.user?.uid ?? '',
          'email': userCredential?.user?.email ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'product': widget.product.toJson(),
          'count': 1
        });

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) {
              // 이 부분은 별도 컴포넌트 클래스로 빼도 될듯
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                title: const Text('장바구니 담기'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('장바구니 등록 완료'),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              );
            },
          );

          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     // TODO: uid 처리
          //     builder: (context) => const CartScreen(uid: ''),
          //   ),
          // );

          // context.push('/cart/:uid', extra: '');
        }
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.red[100],
        ),
        child: const Center(
          child: Text(
            '장바구니',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}
