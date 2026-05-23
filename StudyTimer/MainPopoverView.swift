import SwiftUI

struct MainPopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var remindersManager: RemindersManager
    
    @State private var newMaterialName: String = ""
    @State private var isShowingAddMaterial = false
    @State private var isRegistering = false
    @State private var showSuccessBanner = false
    @State private var successBannerMessage = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HeaderView(timerManager: timerManager)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Active Session Card (Aesthetics Focused)
                    TimerDisplayCard(timerManager: timerManager)
                    
                    // MARK: - Material Retroactive Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("教材の選択")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        if timerManager.materials.isEmpty {
                            Text("教材が登録されていません。下部で追加してください。")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                                .italic()
                        } else {
                            Picker("", selection: $timerManager.selectedMaterial) {
                                ForEach(timerManager.materials, id: \.self) { material in
                                    Text(material).tag(material)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Register Button
                    VStack(spacing: 8) {
                        Button(action: registerSession) {
                            HStack {
                                if isRegistering {
                                    ProgressView()
                                        .controlSize(.small)
                                        .colorInvert()
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                Text("リマインダーに登録してリセット")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(timerManager.secondsElapsed == 0 || timerManager.selectedMaterial.isEmpty || isRegistering)
                        .opacity((timerManager.secondsElapsed == 0 || timerManager.selectedMaterial.isEmpty) ? 0.5 : 1.0)
                        
                        if timerManager.secondsElapsed == 0 {
                            Text("※タイマーを開始して学習時間を計測してください。")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // MARK: - Material Management Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("教材の管理")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    isShowingAddMaterial.toggle()
                                }
                            }) {
                                Image(systemName: isShowingAddMaterial ? "minus.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if isShowingAddMaterial {
                            HStack {
                                TextField("新しい教材名...", text: $newMaterialName)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12))
                                
                                Button(action: addMaterial) {
                                    Text("追加")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .disabled(newMaterialName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Materials List
                        VStack(spacing: 6) {
                            ForEach(timerManager.materials, id: \.self) { material in
                                HStack {
                                    Text(material)
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Button(action: {
                                        timerManager.deleteMaterial(material)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(.plain)
                                    .buttonHoverEffect()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.5))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 15)
                }
                .padding(.vertical)
            }
            
            // MARK: - Banner Notification for Actions
            if showSuccessBanner {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successBannerMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.15))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: { errorMessage = "" }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // MARK: - EventKit Authorization Footer
            FooterView(remindersManager: remindersManager)
        }
        .frame(width: 320, height: 440)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
    
    // MARK: - Logic Helper Methods
    
    private func addMaterial() {
        let name = newMaterialName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            timerManager.addMaterial(name)
            newMaterialName = ""
            withAnimation(.spring()) {
                isShowingAddMaterial = false
            }
        }
    }
    
    private func registerSession() {
        guard timerManager.secondsElapsed > 0 else { return }
        guard !timerManager.selectedMaterial.isEmpty else { return }
        
        isRegistering = true
        errorMessage = ""
        
        // Calculate minutes (rounding to nearest)
        let minutes = Int(round(Double(timerManager.secondsElapsed) / 60.0))
        let material = timerManager.selectedMaterial
        let reminderTitle = "[StudyLog]\(material):\(minutes)"
        
        remindersManager.addReminder(title: reminderTitle) { success, error in
            DispatchQueue.main.async {
                self.isRegistering = false
                if success {
                    self.timerManager.reset()
                    self.triggerSuccessBanner("リマインダーに登録しました: \(reminderTitle)")
                } else {
                    if let err = error {
                        self.errorMessage = "エラー: \(err.localizedDescription)"
                    } else {
                        self.errorMessage = "リマインダーの登録に失敗しました。"
                    }
                }
            }
        }
    }
    
    private func triggerSuccessBanner(_ message: String) {
        successBannerMessage = message
        withAnimation(.easeIn(duration: 0.25)) {
            showSuccessBanner = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.showSuccessBanner = false
            }
        }
    }
}

// MARK: - Visual Effect View for Glassmorphism Background

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Child Subviews (Aesthetic Upgrades)

struct HeaderView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        HStack {
            Image(systemName: "timer")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.blue)
            
            Text("StudyTimer")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
            
            Spacer()
            
            if timerManager.isRunning {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.green.opacity(0.8), radius: 3)
                Text("計測中")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                Text("一時停止中")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
    }
}

struct TimerDisplayCard: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(timerManager.formatFullTime(timerManager.secondsElapsed))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .contentTransition(.numericText(value: Double(timerManager.secondsElapsed)))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            HStack(spacing: 16) {
                // Play/Pause Button
                Button(action: {
                    timerManager.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        Text(timerManager.isRunning ? "一時停止" : "再開")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(timerManager.isRunning ? Color.orange : Color.green)
                    .cornerRadius(15)
                    .shadow(color: (timerManager.isRunning ? Color.orange : Color.green).opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                
                // Reset Button
                Button(action: {
                    timerManager.reset()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("リセット")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal)
    }
}

struct FooterView: View {
    @ObservedObject var remindersManager: RemindersManager
    
    var body: some View {
        HStack {
            Image(systemName: remindersManager.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                .foregroundColor(remindersManager.isAuthorized ? .blue : .orange)
                .font(.system(size: 11))
            
            Text("リマインダー連携:")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            
            Text(remindersManager.permissionStatusText)
                .font(.system(size: 10))
                .foregroundColor(remindersManager.isAuthorized ? .primary : .secondary)
            
            Spacer()
            
            if !remindersManager.isAuthorized {
                Button(action: {
                    remindersManager.requestAccess { _, _ in }
                }) {
                    Text("許可する")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
    }
}

// Hover effect modifier
struct ButtonHoverEffect: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hover
                }
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .opacity(isHovered ? 0.9 : 1.0)
    }
}

extension View {
    func buttonHoverEffect() -> some View {
        self.modifier(ButtonHoverEffect())
    }
}
