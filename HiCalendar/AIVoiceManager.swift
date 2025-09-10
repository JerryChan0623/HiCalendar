//
//  AIVoiceManager.swift
//  HiCalendar
//
//  Created on 2024. AI语音交互管理器
//

import SwiftUI
import Speech
import AVFoundation
import Combine

// MARK: - AI语音管理器
class AIVoiceManager: NSObject, ObservableObject {
    static let shared = AIVoiceManager()
    
    // MARK: - 语音识别相关
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - 语音合成相关
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - 状态管理
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var isSpeaking = false
    @Published var recognizedText = ""
    @Published var aiResponse = ""
    @Published var hasPermission = false
    @Published var errorMessage: String?
    @Published var recordingDuration: TimeInterval = 0
    
    // MARK: - AI对话管理器
    private let conversationManager = AIConversationManager.shared
    private var recordingTimer: Timer?
    
    private override init() {
        // 安全初始化语音识别器
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")) ?? SFSpeechRecognizer()
        super.init()
        
        // 检查语音识别器是否可用
        guard speechRecognizer != nil else {
            DispatchQueue.main.async {
                self.hasPermission = false
                self.errorMessage = "设备不支持语音识别功能"
            }
            return
        }
        
        setupAudio()
        speechSynthesizer.delegate = self
        // 不在初始化时自动请求权限，延迟到用户点击AI按钮时请求
        checkExistingPermissions()
    }
    
    // MARK: - 权限管理
    
    /// 检查现有权限状态（不弹框）
    private func checkExistingPermissions() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let audioStatus = AVAudioSession.sharedInstance().recordPermission
        
        DispatchQueue.main.async {
            self.hasPermission = (speechStatus == .authorized && audioStatus == .granted)
            print("🎤 语音权限状态 - 语音识别: \(speechStatus.rawValue), 麦克风: \(audioStatus.rawValue)")
        }
    }
    
    /// 请求语音权限（用户交互时调用）
    func requestPermissions() {
        Task {
            // 请求语音识别权限
            let speechStatus = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            
            // 请求麦克风权限
            let audioStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            
            await MainActor.run {
                self.hasPermission = (speechStatus == .authorized && audioStatus)
                if !self.hasPermission {
                    var messages: [String] = []
                    
                    switch speechStatus {
                    case .notDetermined:
                        messages.append("需要语音识别权限")
                    case .denied:
                        messages.append("语音识别权限被拒绝，请在设置中开启")
                    case .restricted:
                        messages.append("语音识别功能受限")
                    case .authorized:
                        break
                    @unknown default:
                        messages.append("语音识别权限状态未知")
                    }
                    
                    if !audioStatus {
                        messages.append("需要麦克风权限，请在设置中开启")
                    }
                    
                    self.errorMessage = messages.isEmpty ? "需要麦克风和语音识别权限才能使用语音功能" : messages.joined(separator: "，")
                } else {
                    self.errorMessage = nil
                    print("✅ 语音权限获取成功")
                }
            }
        }
    }
    
    private func setupAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // 使用更温和的音频会话设置
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            // 不在初始化时就激活，而是在需要时激活
        } catch {
            DispatchQueue.main.async {
                print("❌ 音频会话设置失败: \(error)")
                self.errorMessage = "音频设置失败：\(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 语音识别
    func startListening() {
        guard hasPermission else {
            DispatchQueue.main.async {
                self.errorMessage = "需要麦克风和语音识别权限"
            }
            requestPermissions()
            return
        }
        
        guard !isListening else {
            print("已经在监听中，忽略重复调用")
            return
        }
        
        // 停止之前的任务
        stopListening()
        
        // 重置状态
        DispatchQueue.main.async {
            self.recognizedText = ""
            self.errorMessage = nil
            self.recordingDuration = 0
        }
        
        // 开始计时
        startRecordingTimer()
        
        // 安全获取音频输入节点
        let inputNode: AVAudioInputNode
        do {
            inputNode = audioEngine.inputNode
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "无法获取音频输入设备：\(error.localizedDescription)"
            }
            return
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "无法创建语音识别请求"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 检查语音识别器是否可用
        guard let speechRecognizer = speechRecognizer else {
            DispatchQueue.main.async {
                self.errorMessage = "语音识别器不可用"
            }
            return
        }
        
        // 开始识别任务
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                    // 不再在result.isFinal时自动处理，而是等待手动停止
                }
                
                if let error = error {
                    print("❌ 语音识别错误: \(error)")
                    self?.errorMessage = "语音识别失败，请重试"
                    self?.stopListening()
                }
            }
        }
        
        // 配置音频输入
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // 检查音频格式是否有效
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            DispatchQueue.main.async {
                self.errorMessage = "无效的音频格式"
            }
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // 启动音频引擎
        do {
            // 在启动引擎前激活音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            DispatchQueue.main.async {
                print("❌ 音频引擎启动失败: \(error)")
                self.errorMessage = "无法启动录音：\(error.localizedDescription)"
            }
        }
    }
    
    func stopListening() {
        guard isListening else { return } // 防止重复停止
        
        do {
            // 先停止识别任务
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil
            
            // 再停止音频引擎
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }
            
            // 最后释放音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            // 停止计时
            self.stopRecordingTimer()
            
            DispatchQueue.main.async {
                self.isListening = false
                // 停止录音后，自动处理识别的文本（类似微信语音）
                let finalText = self.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !finalText.isEmpty {
                    self.processVoiceInput(finalText)
                }
                self.recordingDuration = 0
            }
        } catch {
            DispatchQueue.main.async {
                print("❌ 停止录音时出错: \(error)")
                self.isListening = false // 确保状态正确
            }
        }
    }
    
    // MARK: - AI处理 (通过Supabase + Gemini)
    private func processVoiceInput(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "没有识别到有效语音，请重试"
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let response = try await callGeminiAPI(with: text)
                
                await MainActor.run {
                    self.aiResponse = response.conclusion + " " + response.sarcasm
                    self.isProcessing = false
                    
                    // 执行相应动作
                    self.executeAIAction(response)
                    
                    // 语音播报回复
                    self.speak(response.conclusion)
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "AI处理失败: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }

    /// 文本输入处理：与语音一致的轻量入口（不强制播报，可沿用现有执行逻辑）
    func processText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isProcessing = true
        Task {
            do {
                let response = try await callGeminiAPI(with: trimmed)
                await MainActor.run {
                    self.aiResponse = response.conclusion + " " + response.sarcasm
                    self.isProcessing = false
                    self.executeAIAction(response)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "AI处理失败: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - 调用Supabase Edge Function (Gemini)
    private func callGeminiAPI(with input: String) async throws -> AIResponse {
        let url = URL(string: "https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/ai-voice-chat")!
        
        // 获取当前用户事件作为上下文
        let currentEvents = EventStorageManager.shared.events.map { event in
            EventContext(
                title: event.title,
                startAt: event.startAt?.ISO8601Format(),
                details: event.details
            )
        }
        
        let requestBody = GeminiRequest(
            input: input,
            userContext: currentEvents,
            timezone: "Asia/Shanghai"
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw AIError.networkError("API请求失败")
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        // 转换GeminiResponse为AIResponse
        let extractedEvent: Event? = nil // 暂时为空，后续实现
        
        return AIResponse(
            conclusion: geminiResponse.conclusion,
            sarcasm: geminiResponse.sarcasm,
            suggestion: geminiResponse.suggestion,
            actionType: AIResponse.AIActionType(rawValue: geminiResponse.actionType) ?? .unknown,
            extractedEvent: extractedEvent,
            message: geminiResponse.message
        )
    }
    
    private func executeAIAction(_ response: AIResponse) {
        switch response.actionType {
        case .createEvent:
            // 执行创建事项逻辑
            if let event = response.extractedEvent {
                EventStorageManager.shared.addEvent(event)
                print("✅ AI创建事项: \(event.title)")
            }
            
        case .queryEvents:
            // 查询逻辑已在AI响应中处理
            break
            
        case .modifyEvent:
            // 修改事项逻辑（可扩展）
            break
            
        case .deleteEvent:
            // 删除事项逻辑（可扩展）
            break
            
        case .checkConflict:
            // 冲突处理逻辑
            break
            
        case .unknown:
            // 未知指令处理
            break
        }
    }
    
    // MARK: - 语音合成
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        DispatchQueue.main.async {
            // 停止当前播放
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 0.8
            
            self.isSpeaking = true
            self.speechSynthesizer.speak(utterance)
        }
    }
    
    func stopSpeaking() {
        DispatchQueue.main.async {
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            self.isSpeaking = false
        }
    }
    
    // MARK: - 录音计时器
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.recordingDuration += 0.1
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - 快捷语音命令
    func quickVoiceCommand() {
        // 模拟快速语音指令处理
        let quickCommands = [
            "今天有什么安排？",
            "明天有事吗？",
            "这周末有什么计划？"
        ]
        
        if let randomCommand = quickCommands.randomElement() {
            recognizedText = randomCommand
            processVoiceInput(randomCommand)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AIVoiceManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

// MARK: - AI对话管理器
class AIConversationManager: ObservableObject {
    static let shared = AIConversationManager()
    
    private let eventStorageManager = EventStorageManager.shared
    
    private init() {}
    
    func processUserInput(_ input: String) async -> AIResponse {
        // 简化版AI处理逻辑，可以后续集成真实AI API
        return await processNaturalLanguage(input)
    }
    
    private func processNaturalLanguage(_ input: String) async -> AIResponse {
        let lowercased = input.lowercased()
        
        // 意图识别
        if isCreateIntent(lowercased) {
            return await handleCreateEvent(input)
        } else if isQueryIntent(lowercased) {
            return await handleQueryEvents(input)
        } else if isModifyIntent(lowercased) {
            return await handleModifyEvent(input)
        } else {
            return AIResponse(
                conclusion: "我没有完全理解你的意思",
                sarcasm: "可能你说得太复杂了，我这个小脑瓜有点转不过来",
                suggestion: "你可以说\"明天三点开会\"或者\"今天有什么安排\"这样的话",
                actionType: .unknown,
                extractedEvent: nil
            )
        }
    }
    
    // MARK: - 意图识别
    private func isCreateIntent(_ input: String) -> Bool {
        let createKeywords = ["创建", "添加", "新建", "安排", "约", "会议", "开会", "提醒", "记住"]
        let timeKeywords = ["今天", "明天", "后天", "周", "点", "号", "月"]
        
        return createKeywords.contains { input.contains($0) } ||
               timeKeywords.contains { input.contains($0) }
    }
    
    private func isQueryIntent(_ input: String) -> Bool {
        let queryKeywords = ["什么", "有没有", "查看", "看看", "安排", "计划", "忙不忙"]
        return queryKeywords.contains { input.contains($0) }
    }
    
    private func isModifyIntent(_ input: String) -> Bool {
        let modifyKeywords = ["修改", "改", "取消", "删除", "推迟", "提前"]
        return modifyKeywords.contains { input.contains($0) }
    }
    
    // MARK: - 处理创建事项
    private func handleCreateEvent(_ input: String) async -> AIResponse {
        let eventData = extractEventData(from: input)
        
        if !eventData.title.isEmpty {
            // 创建Event对象
            let newEvent = Event(
                title: eventData.title,
                startAt: eventData.startTime,
                endAt: eventData.endTime,
                details: eventData.details
            )
            
            return AIResponse(
                conclusion: "好的，我来帮你创建这个事项",
                sarcasm: "又有新任务了，你可真是个大忙人！",
                suggestion: "记得设置提醒，别到时候又说忘了",
                actionType: .createEvent,
                extractedEvent: newEvent
            )
        } else {
            return AIResponse(
                conclusion: "我没有找到要创建的事项内容",
                sarcasm: "你这说了半天，到底要干啥呀？",
                suggestion: "试试说\"明天下午三点开会\"这样更具体的话",
                actionType: .unknown,
                extractedEvent: nil
            )
        }
    }
    
    // MARK: - 处理查询事项
    private func handleQueryEvents(_ input: String) async -> AIResponse {
        let timeRange = extractTimeRange(from: input)
        let events = getEventsInRange(timeRange)
        
        if events.isEmpty {
            let timeDesc = describeTimeRange(timeRange)
            return AIResponse(
                conclusion: "\(timeDesc)没有安排",
                sarcasm: "哇，难得清闲啊，可以偷懒了！",
                suggestion: "不如趁机安排点有意思的事情？",
                actionType: .queryEvents,
                message: "\(timeDesc)你没有任何安排，可以好好休息一下。要不要趁机安排点什么有趣的活动？"
            )
        } else {
            let timeDesc = describeTimeRange(timeRange)
            let eventList = events.map { "• \($0.title)\(formatEventTime($0))" }.joined(separator: "\n")
            
            return AIResponse(
                conclusion: "\(timeDesc)有\(events.count)个安排",
                sarcasm: "看起来挺忙的嘛，别累死了！",
                suggestion: "记得劳逸结合，该休息就休息",
                actionType: .queryEvents,
                message: "\(timeDesc)你有\(events.count)个安排：\n\(eventList)\n\n记得合理安排时间哦！"
            )
        }
    }
    
    // MARK: - 处理修改事项
    private func handleModifyEvent(_ input: String) async -> AIResponse {
        return AIResponse(
            conclusion: "修改功能正在开发中",
            sarcasm: "想改就改，你以为我是万能的呀！",
            suggestion: "先用手动编辑，语音修改功能很快就来",
            actionType: .modifyEvent,
            message: "修改事项功能正在开发中，你可以先在应用里手动编辑。很快就会支持语音修改啦！"
        )
    }
    
    // MARK: - 辅助方法
    private func extractEventData(from input: String) -> EventData {
        var title = ""
        var startTime: Date? = nil
        let details: String? = nil
        
        // 简化版事项提取逻辑
        let timePattern = #"(今天|明天|后天|\d+[号日])\s*(上午|下午|晚上)?(\d{1,2})[点:时](\d{1,2}分?)?"#
        
        if let timeMatch = input.range(of: timePattern, options: .regularExpression) {
            // 提取时间
            startTime = parseDateTime(from: String(input[timeMatch]))
            
            // 剩余部分作为标题
            let withoutTime = input.replacingCharacters(in: timeMatch, with: "")
            title = withoutTime.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // 没有时间信息，整个输入作为标题
            title = input.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 清理标题
        title = title.replacingOccurrences(of: "创建|添加|新建|安排|提醒我", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return EventData(title: title, startTime: startTime, endTime: nil, details: details)
    }
    
    private func parseDateTime(from timeStr: String) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // 简化版时间解析
        if timeStr.contains("明天") {
            components.day! += 1
        } else if timeStr.contains("后天") {
            components.day! += 2
        }
        
        // 提取小时
        if let hourMatch = timeStr.range(of: #"\d{1,2}"#, options: .regularExpression) {
            if let hour = Int(timeStr[hourMatch]) {
                components.hour = hour
                if timeStr.contains("下午") && hour < 12 {
                    components.hour! += 12
                }
            }
        }
        
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components)
    }
    
    private func extractTimeRange(from input: String) -> TimeRange {
        if input.contains("今天") {
            return .today
        } else if input.contains("明天") {
            return .tomorrow
        } else if input.contains("这周") || input.contains("本周") {
            return .thisWeek
        } else {
            return .today
        }
    }
    
    private func getEventsInRange(_ range: TimeRange) -> [Event] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let events = eventStorageManager.events
        
        return events.filter { event in
            guard let startAt = event.startAt else { return false }
            let eventDay = calendar.startOfDay(for: startAt)
            
            switch range {
            case .today:
                return calendar.isDate(eventDay, inSameDayAs: today)
            case .tomorrow:
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                return calendar.isDate(eventDay, inSameDayAs: tomorrow)
            case .thisWeek:
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                return eventDay >= weekStart && eventDay < weekEnd
            }
        }.sorted { $0.startAt! < $1.startAt! }
    }
    
    private func describeTimeRange(_ range: TimeRange) -> String {
        switch range {
        case .today: return "今天"
        case .tomorrow: return "明天"
        case .thisWeek: return "这周"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatEventTime(_ event: Event) -> String {
        guard let startAt = event.startAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return " (\(formatter.string(from: startAt)))"
    }
}

// MARK: - Gemini API数据结构
struct GeminiRequest: Codable {
    let input: String
    let userContext: [EventContext]
    let timezone: String
}

struct EventContext: Codable {
    let title: String
    let startAt: String?
    let details: String?
}

struct GeminiResponse: Codable {
    let conclusion: String
    let sarcasm: String
    let suggestion: String
    let actionType: String
    let message: String
    let eventData: EventData?
}

// MARK: - 数据结构
struct EventData: Codable {
    let title: String
    let startTime: Date?  // 直接使用Date类型
    let endTime: Date?    // 直接使用Date类型
    let details: String?
    
    // 方便初始化
    init(title: String, startTime: Date? = nil, endTime: Date? = nil, details: String? = nil) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.details = details
    }
}

enum TimeRange {
    case today
    case tomorrow
    case thisWeek
}

enum AIError: Error {
    case networkError(String)
    case decodingError(String)
    case invalidResponse(String)
    
    var localizedDescription: String {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .decodingError(let message):
            return "数据解析错误: \(message)"
        case .invalidResponse(let message):
            return "无效响应: \(message)"
        }
    }
}

// MARK: - 扩展AIResponse
extension AIResponse {
    var extractedEventData: EventData? {
        get {
            // 从extractedEvent转换为EventData
            guard let event = extractedEvent else { return nil }
            return EventData(
                title: event.title,
                startTime: event.startAt,
                endTime: event.endAt,
                details: event.details
            )
        }
        set {
            // 暂时不实现setter，因为需要修改struct
            // 在实际使用中直接使用extractedEvent
        }
    }
}
