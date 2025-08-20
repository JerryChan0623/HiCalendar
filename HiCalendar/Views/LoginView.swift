//
//  LoginView.swift
//  HiCalendar
//
//  Created on 2024. Neobrutalism Login Interface
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = SupabaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingResetPassword = false
    @State private var showError = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                BrandColor.neutral100
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: BrandSpacing.xxl) {
                        // Logo和标题
                        VStack(spacing: BrandSpacing.lg) {
                            Text("🗓️")
                                .font(.system(size: 80))
                                .padding(BrandSpacing.xl)
                                .background(
                                    Circle()
                                        .fill(BrandColor.primaryYellow)
                                        .neobrutalStyle(cornerRadius: 100, borderWidth: BrandBorder.thick)
                                )
                            
                            Text("HiCalendar")
                                .font(BrandFont.display(size: 36, weight: .black))
                                .foregroundColor(BrandColor.neutral900)
                            
                            Text("你的个性日历助手")
                                .font(BrandFont.body(size: 16, weight: .medium))
                                .foregroundColor(BrandColor.neutral500)
                        }
                        .padding(.top, BrandSpacing.xxl)
                        
                        // 登录表单
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
                                
                                SecureField("输入密码", text: $password)
                                    .textFieldStyle(NeobrutalismTextFieldStyle())
                                    .focused($focusedField, equals: .password)
                            }
                            
                            // 忘记密码
                            Button(action: {
                                showingResetPassword = true
                            }) {
                                Text("忘记密码？")
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                    .foregroundColor(BrandColor.primaryBlue)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, BrandSpacing.lg)
                        
                        // 登录按钮
                        VStack(spacing: BrandSpacing.md) {
                            Button(action: signIn) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("登录")
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
                            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                            .padding(.horizontal, BrandSpacing.lg)
                            
                            // 分割线
                            HStack {
                                Rectangle()
                                    .fill(BrandColor.neutral300)
                                    .frame(height: 2)
                                Text("或")
                                    .font(BrandFont.body(size: 14, weight: .medium))
                                    .foregroundColor(BrandColor.neutral500)
                                    .padding(.horizontal, BrandSpacing.md)
                                Rectangle()
                                    .fill(BrandColor.neutral300)
                                    .frame(height: 2)
                            }
                            .padding(.horizontal, BrandSpacing.lg)
                            
                            // 注册按钮
                            Button(action: {
                                showingSignUp = true
                            }) {
                                Text("创建新账号")
                                    .font(BrandFont.body(size: 18, weight: .bold))
                                    .foregroundColor(BrandColor.neutral900)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: BrandRadius.md)
                                    .fill(BrandColor.primaryYellow)
                                    .neobrutalStyle(cornerRadius: BrandRadius.md, borderWidth: BrandBorder.thick)
                            )
                            .padding(.horizontal, BrandSpacing.lg)
                        }
                    }
                    .padding(.bottom, BrandSpacing.xxl)
                }
            }
            .navigationDestination(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingResetPassword) {
                ResetPasswordView()
            }
            .alert("登录失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(authManager.errorMessage ?? "请检查邮箱和密码")
            }
            .onAppear {
                focusedField = .email
            }
        }
    }
    
    private func signIn() {
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                showError = true
            }
        }
    }
}

// MARK: - Neobrutalism文本框样式
struct NeobrutalismTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(BrandFont.body(size: 16, weight: .medium))
            .padding(BrandSpacing.md)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: BrandRadius.sm)
                    .stroke(BrandColor.neutral900, lineWidth: BrandBorder.regular)
            )
    }
}

// MARK: - 重置密码视图
struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: BrandSpacing.xl) {
                Text("重置密码")
                    .font(BrandFont.display(size: 24, weight: .bold))
                    .foregroundColor(BrandColor.neutral900)
                    .padding(.top, BrandSpacing.xl)
                
                Text("输入你的邮箱地址，我们将发送重置密码链接")
                    .font(BrandFont.body(size: 14, weight: .medium))
                    .foregroundColor(BrandColor.neutral500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BrandSpacing.lg)
                
                TextField("your@email.com", text: $email)
                    .textFieldStyle(NeobrutalismTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, BrandSpacing.lg)
                
                Button(action: resetPassword) {
                    Text("发送重置链接")
                        .font(BrandFont.body(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.sm)
                                .fill(BrandColor.primaryBlue)
                                .neobrutalStyle(cornerRadius: BrandRadius.sm, borderWidth: BrandBorder.regular)
                        )
                }
                .padding(.horizontal, BrandSpacing.lg)
                .disabled(email.isEmpty)
                
                Spacer()
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(BrandColor.neutral900)
                }
            }
            .alert("发送成功", isPresented: $showSuccess) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("请检查你的邮箱")
            }
        }
    }
    
    private func resetPassword() {
        // TODO: 实现密码重置
        showSuccess = true
    }
}

#Preview {
    LoginView()
}