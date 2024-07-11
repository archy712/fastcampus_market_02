import 'dart:developer';

import 'package:fastcampus_market_02/login/provider/login_provider.dart';
import 'package:fastcampus_market_02/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailTextController = TextEditingController();
  TextEditingController pwdTextController = TextEditingController();

  // Google email/password Login 기능
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      log('credential : ${credential.toString()}');

      // 로그인 되었을 때 유저 정보를 얻기 (임시)
      userCredential = credential;

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        log(e.toString());
      } else if (e.code == 'wrong-password') {
        log(e.toString());
      }
    } catch (e) {
      log(e.toString());
    }
  }

  // Google Login 기능
  Future<UserCredential?> signInWithGoogle() async {
    // 구글 사용자 정보 선택 또는 입력 팝업창
    final GoogleSignInAccount? googleAccount = await GoogleSignIn().signIn();

    // 입력창에서 선택/입력한 정보를 받아와서
    final GoogleSignInAuthentication? googleAuth =
        await googleAccount?.authentication;

    // 구글 인증
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/fastcampus_logo.png'),
              const Text(
                '패캠마트',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 64),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '이메일',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일 주소를 입력해 주세요!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: pwdTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '비밀번호',
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해 주세요!';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Consumer(
                  builder: (context, ref, child) {
                    return MaterialButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // save() 처리는 Optional
                          _formKey.currentState!.save();

                          final result = await signIn(
                            emailTextController.text.trim(),
                            pwdTextController.text.trim(),
                          );

                          if (result == null) {
                            // 로그인 실패 메시지
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('로그인 실패'),
                                ),
                              );
                            }
                            return;
                          }

                          // 결과값이 있을 경우
                          ref.watch(userCredentialProvider.notifier).state = result;

                          // 로그인 성공 메시지
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('로그인 성공'),
                              ),
                            );
                          }
                        }

                        // 로그인 성공했으면 홈으로 이동
                        if (context.mounted) {
                          context.go('/');
                        }
                      },
                      height: 48,
                      minWidth: double.infinity,
                      color: Colors.red,
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                ),
              ),
              TextButton(
                onPressed: () => context.push('/sign_up'),
                child: const Text(
                  '계정이 없나요? 회원가입',
                ),
              ),
              const Divider(),
              // GestureDetector 둘 중 아무거나 사용 가능
              InkWell(
                onTap: () async {
                  final userCredential = await signInWithGoogle();

                  if (userCredential == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('로그인 실패'),
                        ),
                      );
                    }
                    return;
                  }

                  if (context.mounted) {
                    context.go('/');
                  }
                },
                child: Image.asset('assets/btn_google_signin.png'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
