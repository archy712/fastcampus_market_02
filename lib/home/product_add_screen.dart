import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastcampus_market_02/model/category.dart';
import 'package:fastcampus_market_02/model/product.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProductAddScreen extends StatefulWidget {
  const ProductAddScreen({super.key});

  @override
  State<ProductAddScreen> createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSale = false;

  final db = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  // 사진 라이브러리 선택 및 표시 관련
  Uint8List? imageData;
  XFile? image;

  // 기본 카테고리
  Category? selectedCategory;

  TextEditingController titleTextController = TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();
  TextEditingController priceTextController = TextEditingController();
  TextEditingController stockTextController = TextEditingController();
  TextEditingController salePercentTextController = TextEditingController();

  // 카테고리 리스트 변수 선언
  List<Category> categoryItems = [];

  // 카테고리 가져오기
  Future<List<Category>> _fetchCategories() async {
    // Firestore Collection 데이터 가져오기
    final QuerySnapshot<Map<String, dynamic>> categories =
        await db.collection('category').get();

    // 카테고리 모델 리스트에 담기
    for (QueryDocumentSnapshot<Map<String, dynamic>> doc in categories.docs) {
      categoryItems.add(
        // 방법 1 (기본)
        // Category(
        //   docId: doc.id,
        //   title: doc.data()['title'],
        // 방법 2 (fromJson)
        Category.fromJson(
          doc.data(),
        ).copyWith(docId: doc.id),
      );
    }

    // 첫번째 카테고리 기본 선택
    setState(() {
      selectedCategory = categoryItems.first;
    });

    return categoryItems;
  }

  // 상품 1개 등록하기
  Future addProduct() async {
    // 사진이 등록되어 있을 경우만 처리
    if (imageData != null) {
      // storage 레퍼런스를 얻고
      final Reference storageRef = storage.ref().child(
            '${DateTime.now().millisecondsSinceEpoch}_${image?.name ?? '??'}.jpg',
          );
      // 이미지 압축 처리를 하고
      Uint8List compressedData = await _imageCompressList(imageData!);

      // 이미지 데이터를 storage 에 쓰기
      await storageRef.putData(compressedData);

      // 다운로드 링크를 얻어와서
      String downloadLink = await storageRef.getDownloadURL();

      // Product Model 생성
      Product product = Product(
        title: titleTextController.text,
        description: descriptionTextController.text,
        price: int.parse(priceTextController.text),
        stock: int.parse(stockTextController.text),
        isSale: isSale,
        saleRate: salePercentTextController.text.isNotEmpty
            ? double.parse(salePercentTextController.text)
            : 0,
        imgUrl: downloadLink,
        // "현재 시각을" ms로 변환하여 Int로 반환
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // Firestore Collection 저장 : products
      final DocumentReference<Map<String, dynamic>> doc =
          await db.collection('products').add(
                product.toJson(),
              );

      // final 사용하여 return 데이터 타입 생략
      // final doc = await db.collection('products').add(
      //   product.toJson(),
      // );

      // Firestore Collection 저장 : products 밑에 category 컬렉션
      await doc.collection('category').add(
            selectedCategory?.toJson() ?? {},
          );

      // category 레퍼런스를 얻어와서
      final DocumentReference<Map<String, dynamic>> categoryRef = db.collection('category').doc(
            selectedCategory?.docId,
          );

      // final 사용하여 return 데이터 타입 생략
      // final categoryRef = db.collection('category').doc(
      //   selectedCategory?.docId,
      // );

      // category 레퍼런스의 products 컬렉션에 등록
      await categoryRef.collection('products').add({'docId': doc.id});
    }
  }

  // 상품 이미지 용량 압축
  Future<Uint8List> _imageCompressList(Uint8List list) async {
    Uint8List result = await FlutterImageCompress.compressWithList(
      list,
      quality: 50,
    );
    return result;
  }

  // 상품 일괄 등록
  Future addProductsBatch() async {
    // 사진이 등록되어 있을 경우만 처리
    if (imageData != null) {
      // storage 레퍼런스를 얻고
      final Reference storageRef = storage.ref().child(
        '${DateTime.now().millisecondsSinceEpoch}_${image?.name ?? '??'}.jpg',
      );
      // 이미지 압축 처리를 하고
      Uint8List compressedData = await _imageCompressList(imageData!);

      // 이미지 데이터를 storage 에 쓰기
      await storageRef.putData(compressedData);

      // 다운로드 링크를 얻어와서
      String downloadLink = await storageRef.getDownloadURL();

      // 10개 등록 (상품명만 조금 변경)
      for(int i = 0; i < 10; i++) {
        // Product Model 생성
        Product product = Product(
          title: '${titleTextController.text}_$i',
          description: descriptionTextController.text,
          price: int.parse(priceTextController.text),
          stock: int.parse(stockTextController.text),
          isSale: isSale,
          saleRate: salePercentTextController.text.isNotEmpty
              ? double.parse(salePercentTextController.text)
              : 0,
          imgUrl: downloadLink,
          // "현재 시각을" ms로 변환하여 Int로 반환
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        // Firestore Collection 저장 : products
        final DocumentReference<Map<String, dynamic>> doc =
        await db.collection('products').add(
          product.toJson(),
        );

        // final 사용하여 return 데이터 타입 생략
        // final doc = await db.collection('products').add(
        //   product.toJson(),
        // );

        // Firestore Collection 저장 : products 밑에 category 컬렉션
        await doc.collection('category').add(
          selectedCategory?.toJson() ?? {},
        );

        // category 레퍼런스를 얻어와서
        final DocumentReference<Map<String, dynamic>> categoryRef = db.collection('category').doc(
          selectedCategory?.docId,
        );

        // final 사용하여 return 데이터 타입 생략
        // final categoryRef = db.collection('category').doc(
        //   selectedCategory?.docId,
        // );

        // category 레퍼런스의 products 컬렉션에 등록
        await categoryRef.collection('products').add({'docId': doc.id});
      }
    }
  }


  @override
  void initState() {
    super.initState();

    // 페이지 로딩시에 자동 카테고리 처리
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 추가'),
        actions: [
          // 카메라 기능 샘플
          IconButton(
            onPressed: () {
              context.push('/camera');
            },
            icon: const Icon(CupertinoIcons.camera),
          ),
          // 상품 일괄 등록
          IconButton(
            onPressed: () {
              addProductsBatch();
            },
            icon: const Icon(Icons.batch_prediction),
          ),
          // 상품 1개 등록
          IconButton(
            onPressed: () {
              addProduct();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  image = await picker.pickImage(source: ImageSource.gallery);
                  print('${image?.name}, ${image?.path}');
                  imageData = await image?.readAsBytes();
                  setState(() {});
                },
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 240,
                    width: 240,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[200]!,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: imageData == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add),
                              Text(
                                '상품 이미지 추가',
                              ),
                            ],
                          )
                        : Image.memory(
                            imageData!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '기본 정보',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '상품명',
                        hintText: '상품명을 입력하세요!',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '상품명을 입력하세요!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '상품 설명',
                        hintText: '상품 설명을 입력해 주세요!',
                      ),
                      maxLength: 254,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '상품 설명을 입력해 주세요!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '상품 단가',
                        hintText: '1개 가격',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '상품 단가를 입력해 주세요!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: stockTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '재고 수량',
                        hintText: '재고 수량 입력',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '재고 수량을 입력해 주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      value: isSale,
                      title: const Text('할인 여부'),
                      onChanged: (v) {
                        setState(() {
                          isSale = v;
                        });
                      },
                    ),
                    if (isSale)
                      TextFormField(
                        controller: salePercentTextController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '할인율',
                          hintText: '할인율 입력',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      '카테고리 선택',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    categoryItems.isNotEmpty
                        ? DropdownButton<Category>(
                            isExpanded: true,
                            value: selectedCategory,
                            items: categoryItems
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('${e.title}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (s) {
                              setState(() {
                                selectedCategory = s;
                              });
                            },
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
