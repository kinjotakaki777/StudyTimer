import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var secondsElapsed: Int = 0
    @Published var isRunning: Bool = false
    @Published var materials: [String] = []
    @Published var selectedMaterial: String = ""
    
    private var timer: Timer?
    var onTick: ((String) -> Void)?
    
    private let materialsKey = "StudyTimer_Materials"
    private let defaultMaterials = [
        "プログラミング学習",
        "英語学習",
        "読書",
        "資格の勉強",
        "ブログ執筆"
    ]
    
    init() {
        loadMaterials()
    }
    
    // MARK: - Timer Actions
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        notifyTick() // Trigger immediately on start
        
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsElapsed += 1
            self.notifyTick()
        }
        // Run loop mode common ensures the timer runs even when interacting with the UI
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        notifyTick() // Trigger immediately on pause
    }
    
    func reset() {
        pause()
        secondsElapsed = 0
        // pause() already calls notifyTick(), but reset sets secondsElapsed to 0, so call it again to update to 00:00
        notifyTick()
    }
    
    private func notifyTick() {
        let timeString = formatMenuBarTime(secondsElapsed)
        onTick?(timeString)
    }
    
    // MARK: - Formatting Helpers
    
    func formatMenuBarTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatFullTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分\(seconds)秒"
        } else if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    // MARK: - Material Management
    
    func loadMaterials() {
        if let saved = UserDefaults.standard.stringArray(forKey: materialsKey) {
            materials = saved
        } else {
            materials = defaultMaterials
            saveMaterials()
        }
        
        if selectedMaterial.isEmpty, let first = materials.first {
            selectedMaterial = first
        }
    }
    
    func saveMaterials() {
        UserDefaults.standard.set(materials, forKey: materialsKey)
    }
    
    func addMaterial(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !materials.contains(trimmed) else { return }
        
        materials.append(trimmed)
        saveMaterials()
        
        if selectedMaterial.isEmpty {
            selectedMaterial = trimmed
        }
    }
    
    func deleteMaterial(_ name: String) {
        materials.removeAll { $0 == name }
        saveMaterials()
        
        if selectedMaterial == name {
            selectedMaterial = materials.first ?? ""
        }
    }
}
