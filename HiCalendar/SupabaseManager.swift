//
//  SupabaseManager.swift
//  HiCalendar
//
//  Created on 2024. Supabase Authentication Manager
//

import Foundation
import SwiftUI

// 注意: 这个文件使用了Supabase SDK
// 请在Xcode中通过 File > Add Package Dependencies 添加:
// https://github.com/supabase/supabase-swift

// 如果你还没有安装Supabase SDK，这个代码会报错
// 安装后取消下面的注释：

/*
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var isAuthenticated = false
    @Published var currentUser: User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.projectURL)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        // 检查现有会话
        Task {
            await checkSession()
        }
    }
    
    // 检查当前会话
    @MainActor
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    // 注册新用户
    @MainActor
    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            if let user = response.user {
                self.currentUser = user
                self.isAuthenticated = true
                
                // 创建用户profile
                await createUserProfile(for: user)
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = translateError(error)
            throw error
        }
    }
    
    // 登录
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            self.currentUser = response.user
            self.isAuthenticated = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = translateError(error)
            throw error
        }
    }
    
    // 登出
    @MainActor
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            errorMessage = "登出失败: \(error.localizedDescription)"
            throw error
        }
    }
    
    // 重置密码
    @MainActor
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await client.auth.resetPasswordForEmail(email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = translateError(error)
            throw error
        }
    }
    
    // 创建用户配置文件
    private func createUserProfile(for user: User) async {
        // 这里可以在Supabase数据库中创建用户配置文件
        // 例如存储用户名、头像等额外信息
    }
    
    // 错误信息本地化
    private func translateError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("email") && errorString.contains("exists") {
            return "该邮箱已被注册"
        } else if errorString.contains("invalid") && errorString.contains("credentials") {
            return "邮箱或密码错误"
        } else if errorString.contains("password") && errorString.contains("short") {
            return "密码至少需要6个字符"
        } else if errorString.contains("email") && errorString.contains("invalid") {
            return "请输入有效的邮箱地址"
        } else {
            return "操作失败: \(error.localizedDescription)"
        }
    }
}
*/

// 临时的认证管理器（在安装Supabase SDK之前使用）
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private init() {
        // 检查本地存储的登录状态
        checkLocalSession()
    }
    
    func checkLocalSession() {
        // 临时使用UserDefaults
        isAuthenticated = UserDefaults.standard.bool(forKey: "isLoggedIn")
        currentUser = UserDefaults.standard.string(forKey: "userEmail")
    }
    
    func signUp(email: String, password: String) async throws {
        // 临时实现
        await MainActor.run {
            isLoading = true
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络请求
        
        await MainActor.run {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(email, forKey: "userEmail")
            self.isAuthenticated = true
            self.currentUser = email
            isLoading = false
        }
    }
    
    func signIn(email: String, password: String) async throws {
        // 临时实现
        await MainActor.run {
            isLoading = true
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络请求
        
        await MainActor.run {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(email, forKey: "userEmail")
            self.isAuthenticated = true
            self.currentUser = email
            isLoading = false
        }
    }
    
    func signOut() async throws {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
}