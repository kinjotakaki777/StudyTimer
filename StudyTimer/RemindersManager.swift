import Foundation
import EventKit

class RemindersManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var isAuthorized = false
    @Published var permissionStatusText = "未確認"
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        updateStatus(status)
    }
    
    private func updateStatus(_ status: EKAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .notDetermined:
                self.isAuthorized = false
                self.permissionStatusText = "未設定 (クリックして許可)"
            case .restricted:
                self.isAuthorized = false
                self.permissionStatusText = "機能制限あり"
            case .denied:
                self.isAuthorized = false
                self.permissionStatusText = "アクセス拒否 (システム設定から許可してください)"
            case .authorized:
                self.isAuthorized = true
                self.permissionStatusText = "許可済み"
            case .fullAccess:
                self.isAuthorized = true
                self.permissionStatusText = "フルアクセス許可済み"
            case .writeOnly:
                // Write-only allows adding reminders (which is what we do!)
                self.isAuthorized = true
                self.permissionStatusText = "書き込み許可済み"
            @unknown default:
                self.isAuthorized = false
                self.permissionStatusText = "不明なステータス"
            }
        }
    }
    
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { [weak self] granted, error in
                self?.checkAuthorizationStatus()
                completion(granted, error)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
                self?.checkAuthorizationStatus()
                completion(granted, error)
            }
        }
    }
    
    func addReminder(title: String, completion: @escaping (Bool, Error?) -> Void) {
        requestAccess { [weak self] granted, error in
            guard let self = self else { return }
            guard granted else {
                completion(false, error ?? NSError(domain: "RemindersManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Reminders access denied"]))
                return
            }
            
            let reminder = EKReminder(eventStore: self.eventStore)
            reminder.title = title
            
            // Try to find the default calendar for reminders.
            // If default is nil, try to find any reminders calendar.
            if let defaultCal = self.eventStore.defaultCalendarForNewReminders() {
                reminder.calendar = defaultCal
            } else {
                let calendars = self.eventStore.calendars(for: .reminder)
                if let fallbackCal = calendars.first {
                    reminder.calendar = fallbackCal
                } else {
                    // Create a custom calendar if none exists (though usually macOS has one)
                    completion(false, NSError(domain: "RemindersManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "リマインダーのカレンダーが見つかりません"]))
                    return
                }
            }
            
            do {
                try self.eventStore.save(reminder, commit: true)
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }
}
