import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fastcampus_market_02/firebase_options.dart';
import 'package:fastcampus_market_02/home/camera_example_page.dart';
import 'package:fastcampus_market_02/home/cart_screen.dart';
import 'package:fastcampus_market_02/home/home_screen.dart';
import 'package:fastcampus_market_02/home/product_add_screen.dart';
import 'package:fastcampus_market_02/home/product_detail_screen.dart';
import 'package:fastcampus_market_02/login/login_screen.dart';
import 'package:fastcampus_market_02/login/sign_up_screen.dart';
import 'package:fastcampus_market_02/model/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 카메라 레퍼런스 얻기
List<CameraDescription> cameras = [];

// 사용자 정보 (임시) -> 나중에 상태관리로 처리
UserCredential? userCredential;

void main() async {
  // 에뮬레이터 초기화 세팅
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카메라 갯수 얻기 (실 기기에 앞면/뒷면 여부)
  cameras = await availableCameras();

  // kDebug 모드일때 Local Emulator 사용
  if (kDebugMode) {
    try {
      // 구글 로그인을 사용할 경우에는 emulator 사용 불가. > 아래 1줄 주석 처리하고 앱 껏다가 재실행
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    } catch (e) {
      print(e);
    }
  }

  // 앱 실행
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // GoRouter 설정
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      // 홈 화면
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // 장바구니
          GoRoute(
            path: 'cart/:uid',
            builder: (context, state) => CartScreen(
              uid: state.pathParameters['uid'] ?? '',
            ),
          ),
          // 제품 상세 정보
          GoRoute(
            path: 'product',
            builder: (context, state) => ProductDetailScreen(
              product: state.extra as Product,
            ),
          ),
          GoRoute(
            path: 'product/add',
            builder: (context, state) => const ProductAddScreen(),
          ),
        ],
      ),
      // 로그인 화면
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // 회원가입 화면
      GoRoute(
        path: '/sign_up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraExamplePage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FastCampus Market 02',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //home: const HomeScreen(),
      routerConfig: router,
    );
  }
}
