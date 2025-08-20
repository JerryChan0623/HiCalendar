//
//  SignUpView.swift
//  HiCalendar
//
//  Created on 2024. Neobrutalism Sign Up Interface
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var authManager = SupabaseManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var showError = false
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            // 背景
            BrandColor.neutral100
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: BrandSpacing.xl) {
                    // 标题
                    VStack(spacing: BrandSpacing.md) {
                        Text("创建账号")
                            .font(BrandFont.display(size: 32, weight: .black))
                            .foregroundColor(BrandColor.neutral900)
                        
                        Text("开始你的个性化日历之旅")
                            .font(BrandFont.body(size: 16, weight: .medium))
                            .foregroundColor(BrandColor.neutral500)
                    }
                    .padding(.top, BrandSpacing.xxl)
                    
                    // 注册表单
                    VStack(spacing: BrandSpacing.lg) {
                        // 邮箱输入
                        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                            Text("邮箱")
                                .font(BrandFont.body(size: 14, weight: .bold))
                                .foregroundColor(BrandColor.neutral700)
                            
                            TextField("your@email.com", text: $email)
                                .textFieldStyle(NeobrutalismTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                        }
                        
                        // 密码输入
                        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                            Text("密码")
                                .font(BrandFont.body(size: 14, weight: .bold))
                                .foregroundColor(BrandColor.neutral700)
                            
                            SecureField("至少6个字符", text: $password)
                                .textFieldStyle(NeobrutalismTextFieldStyle())
                                .focused($focusedField, equals: .password)
                            
                            // 密码强度指示器
                            PasswordStrengthIndicator(password: password)
                        }
                        
                        // 确认密码
                        VStack(alignment: .leading, spacing: BrandSpacing.sm) {
                            Text("确认密码")
                                .font(BrandFont.body(size: 14, weight: .bold))
                                .foregroundColor(BrandColor.neutral700)
                            
                            SecureField("再次输入密码", text: $confirmPassword)
                                .textFieldStyle(NeobrutalismTextFieldStyle())
                                .focused($focusedField, equals: .confirmPassword)
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("密码不匹配")
                                    .font(BrandFont.body(size: 12, weight: .medium))
                                    .foregroundColor(BrandColor.danger)
                            }
                        }
                        
                        // 服务条款
                        HStack(spacing: BrandSpacing.sm) {
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .font(.title2)
                                    .foregroundColor(agreedToTerms ? BrandColor.primaryBlue : BrandColor.neutral500)
                            }
                            
                            Text("我同意")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.neutral700)
                            +
                            Text(" 服务条款")
                                .font(BrandFont.body(size: 14, weight: .bold))
                                .foregroundColor(BrandColor.primaryBlue)
                                .underline()
                            +
                            Text(" 和")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.neutral700)
                            +
                            Text(" 隐私政策")
                                .font(BrandFont.body(size: 14, weight: .bold))
                                .foregroundColor(BrandColor.primaryBlue)
                                .underline()
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, BrandSpacing.lg)
                    
                    // 注册按钮
                    VStack(spacing: BrandSpacing.md) {
                        Button(action: signUp) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("创建账号")
                                    .font(BrandFont.body(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.md)
                                .fill(BrandColor.primaryBlue)
                                .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.thick)
                        )
                        .disabled(!canSignUp)
                        .padding(.horizontal, BrandSpacing.lg)
                        
                        // 已有账号
                        HStack {
                            Text("已有账号？")
                                .font(BrandFont.body(size: 14, weight: .medium))
                                .foregroundColor(BrandColor.neutral500)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("立即登录")
                                    .font(BrandFont.body(size: 14, weight: .bold))
                                    .foregroundColor(BrandColor.primaryBlue)
                            }
                        }
                    }
                }
                .padding(.bottom, BrandSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("返回")
                            .font(BrandFont.body(size: 16, weight: .bold))
                    }
                    .foregroundColor(BrandColor.neutral900)
                }
            }
        }
        .alert("注册成功", isPresented: $showSuccess) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("账号创建成功，请登录")
        }
        .alert("注册失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "请检查输入信息")
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    private var canSignUp: Bool {
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreedToTerms &&
        !authManager.isLoading
    }
    
    private func signUp() {
        Task {
            do {
                try await authManager.signUp(email: email, password: password)
                showSuccess = true
            } catch {
                showError = true
            }
        }
    }
}

// MARK: - 密码强度指示器
struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.isEmpty {
            return .none
        } else if password.count < 6 {
            return .weak
        } else if password.count < 10 {
            return .medium
        } else {
            return .strong
        }
    }
    
    enum PasswordStrength {
        case none, weak, medium, strong
        
        var color: Color {
            switch self {
            case .none: return BrandColor.neutral300
            case .weak: return BrandColor.danger
            case .medium: return BrandColor.warning
            case .strong: return BrandColor.success
            }
        }
        
        var text: String {
            switch self {
            case .none: return ""
            case .weak: return "弱"
            case .medium: return "中"
            case .strong: return "强"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: BrandSpacing.sm) {
            // 强度条
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < strengthLevel ? strength.color : BrandColor.neutral300)
                        .frame(height: 4)
                }
            }
            .frame(width: 80)
            
            // 强度文字
            if strength != .none {
                Text(strength.text)
                    .font(BrandFont.body(size: 12, weight: .medium))
                    .foregroundColor(strength.color)
            }
            
            Spacer()
        }
    }
    
    private var strengthLevel: Int {
        switch strength {
        case .none: return 0
        case .weak: return 1
        case .medium: return 2
        case .strong: return 3
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}