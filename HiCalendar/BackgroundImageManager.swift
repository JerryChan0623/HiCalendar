//
//  BackgroundImageManager.swift
//  HiCalendar
//
//  Created on 2024. Background Image Management
//

import SwiftUI
import PhotosUI

// MARK: - Background Image Manager
class BackgroundImageManager: ObservableObject {
    static let shared = BackgroundImageManager()
    
    @Published var backgroundImage: UIImage? = nil
    @Published var hasCustomBackground = false
    
    private let userDefaults = UserDefaults.standard
    private let backgroundImageKey = "calendar_background_image"
    private let hasCustomBackgroundKey = "has_custom_background"
    
    private init() {
        loadBackgroundImage()
    }
    
    // 保存图片到UserDefaults
    func saveBackgroundImage(_ image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 保持高质量，避免压缩缩略图
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                DispatchQueue.main.async {
                    self.userDefaults.set(imageData, forKey: self.backgroundImageKey)
                    self.userDefaults.set(true, forKey: self.hasCustomBackgroundKey)
                    
                    self.backgroundImage = image
                    self.hasCustomBackground = true
                    
                    print("✅ 背景图片已保存，尺寸: \(image.size)")
                }
            }
        }
    }
    
    // 从UserDefaults加载图片
    private func loadBackgroundImage() {
        hasCustomBackground = userDefaults.bool(forKey: hasCustomBackgroundKey)
        
        if hasCustomBackground,
           let imageData = userDefaults.data(forKey: backgroundImageKey),
           let image = UIImage(data: imageData) {
            backgroundImage = image
        }
    }
    
    // 删除背景图片
    func removeBackgroundImage() {
        userDefaults.removeObject(forKey: backgroundImageKey)
        userDefaults.set(false, forKey: hasCustomBackgroundKey)
        
        backgroundImage = nil
        hasCustomBackground = false
    }
}

// MARK: - Photo Picker Helper
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}