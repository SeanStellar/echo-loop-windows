import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple 登录凭证获取接口。
///
/// 生产环境通过系统 Sign in with Apple 面板获取 identity token；测试环境可注入
/// 替身，避免 provider 单测依赖平台弹窗。
abstract class AppleSignInCredentialsProvider {
  Future<AuthorizationCredentialAppleID> getCredential({required String nonce});
}

class NativeAppleSignInCredentialsProvider
    implements AppleSignInCredentialsProvider {
  const NativeAppleSignInCredentialsProvider();

  @override
  Future<AuthorizationCredentialAppleID> getCredential({
    required String nonce,
  }) {
    return SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
  }
}
