//
//  AppleAuthManager.swift
//  HiCalendar
//
//  Created on 2024. Apple Sign In Manager
//

import SwiftUI
import AuthenticationServices
import CryptoKit

// Apple登录管理器
class AppleAuthManager: NSObject, ObservableObject {
    static let shared = AppleAuthManager()
    
    @Published var isAuthenticated = false
    @Published var userIdentifier: String? = nil
    @Published var fullName: String? = nil
    @Published var email: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // 用于Apple登录的nonce
    private var currentNonce: String?
    
    private override init() {
        super.init()
        checkAuthenticationState()
    }
    
    // 检查登录状态
    func checkAuthenticationState() {
        if let userIdentifier = UserDefaults.standard.string(forKey: "appleUserIdentifier") {
            // 验证Apple ID凭证状态
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userIdentifier) { [weak self] state, error in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        self?.isAuthenticated = true
                        self?.userIdentifier = userIdentifier
                        self?.fullName = UserDefaults.standard.string(forKey: "appleUserFullName")
                        self?.email = UserDefaults.standard.string(forKey: "appleUserEmail")
                    case .revoked, .notFound:
                        self?.signOut()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // 登出
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
        UserDefaults.standard.removeObject(forKey: "appleUserFullName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        
        isAuthenticated = false
        userIdentifier = nil
        fullName = nil
        email = nil
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleAuthManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple授权完成回调触发")
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ 无法获取Apple ID凭证")
            isLoading = false
            errorMessage = "Apple登录凭证无效"
            return
        }
        
        print("✅ 获得Apple ID凭证，用户ID: \(appleIDCredential.user)")
        
        // 保存用户信息
        let userIdentifier = appleIDCredential.user
        UserDefaults.standard.set(userIdentifier, forKey: "appleUserIdentifier")
        
        // 第一次登录时可以获取到用户信息
        if let fullName = appleIDCredential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            if !name.isEmpty {
                UserDefaults.standard.set(name, forKey: "appleUserFullName")
                self.fullName = name
                print("✅ 获得用户姓名: \(name)")
            }
        }
        
        if let email = appleIDCredential.email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
            self.email = email
            print("✅ 获得用户邮箱: \(email)")
        }
        
        // 更新本地Apple认证状态
        self.userIdentifier = userIdentifier
        self.isAuthenticated = true
        
        // 与Supabase集成
        if let identityToken = appleIDCredential.identityToken,
           let idTokenString = String(data: identityToken, encoding: .utf8),
           let nonce = currentNonce {
            
            print("🔑 准备发送到Supabase，Token长度: \(idTokenString.count)")
            print("🔐 Nonce: \(nonce.prefix(10))...")
            
            Task {
                do {
                    try await SupabaseManager.shared.signInWithApple(
                        idToken: idTokenString,
                        nonce: nonce
                    )
                    await MainActor.run {
                        self.isLoading = false
                        print("✅ 完整登录流程成功")
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Supabase登录失败: \(error.localizedDescription)"
                        self.isLoading = false
                        print("❌ Supabase登录失败但Apple认证成功")
                    }
                }
            }
        } else {
            print("❌ 缺少必要的身份验证数据")
            print("❌ Identity Token存在: \(appleIDCredential.identityToken != nil)")
            print("❌ Current Nonce存在: \(currentNonce != nil)")
            
            self.isLoading = false
            self.errorMessage = "Apple登录数据不完整"
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        
        if let error = error as? ASAuthorizationError {
            switch error.code {
            case .canceled:
                errorMessage = "不登就不登嘛 😤"
            case .failed:
                errorMessage = "登录失败，请重试"
            case .invalidResponse:
                errorMessage = "无效的响应"
            case .notHandled:
                errorMessage = "请求未处理"
            case .unknown:
                errorMessage = "未知错误"
            case .notInteractive:
                errorMessage = "需要用户交互"
            case .matchedExcludedCredential:
                errorMessage = "凭证被排除"
            case .credentialImport:
                errorMessage = "凭证导入失败"
            case .credentialExport:
                errorMessage = "凭证导出失败"
            @unknown default:
                errorMessage = "登录出错"
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleAuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Nonce生成
extension AppleAuthManager {
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func startSignInWithApple() {
        print("🚀 开始Apple登录流程")
        let nonce = randomNonceString()
        currentNonce = nonce
        print("🔐 生成Nonce: \(nonce.prefix(10))...")
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let hashedNonce = sha256(nonce)
        request.nonce = hashedNonce
        
        print("🔒 Hashed Nonce: \(hashedNonce.prefix(10))...")
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        print("🎯 准备显示Apple登录界面")
        authorizationController.performRequests()
        
        isLoading = true
    }
}

// MARK: - Apple登录按钮视图
struct AppleSignInButton: View {
    @StateObject private var authManager = AppleAuthManager.shared
    @Environment(\.colorScheme) var colorScheme
    var onSignIn: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            if let callback = onSignIn {
                // 如果有回调，调用回调处理登录前的逻辑
                callback()
            } else {
                // 如果没有回调，直接开始登录
                authManager.startSignInWithApple()
            }
        }) {
            HStack {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20))
                Text("用 Apple 账号进来 🍎")
                    .font(BrandFont.body(size: 16, weight: .bold))
            }
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(colorScheme == .dark ? .white : .black)
            .cornerRadius(BrandRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: BrandRadius.md)
                    .stroke(BrandColor.outline, lineWidth: BrandBorder.regular)
            )
        }
        .disabled(authManager.isLoading)
        .opacity(authManager.isLoading ? 0.6 : 1.0)
    }
}