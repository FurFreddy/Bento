import SwiftUI
import Combine

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    // Global Settings
    @AppStorage("preview_quality") var previewQuality: String = "medium"
    @AppStorage("image_quality") var imageQuality: String = "medium"
    @AppStorage("thumbnail_layout") var thumbnailLayout: String = "default"
    @AppStorage("safe_mode") var safeMode: Bool = true
    @AppStorage("safe_mode_level") var safeModeLevel: String = "strict"
    @AppStorage("dim_viewed") var dimViewed: Bool = false
    
    // Accounts
    @AppStorage("accounts_json") private var accountsJson: String = "[]"
    @AppStorage("active_account_id") var activeAccountId: String = ""
    
    @Published var accounts: [Account] = []
    
    private init() {
        loadAccounts()
    }
    
    func loadAccounts() {
        if let data = accountsJson.data(using: .utf8) {
            do {
                accounts = try JSONDecoder().decode([Account].self, from: data)
                
                // Set default account if none active
                if activeAccountId.isEmpty && !accounts.isEmpty {
                    activeAccountId = accounts[0].id
                }
            } catch {
                print("Error decoding accounts: \(error)")
            }
        }
    }
    
    func saveAccounts() {
        do {
            let data = try JSONEncoder().encode(accounts)
            accountsJson = String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            print("Error encoding accounts: \(error)")
        }
    }
    
    var activeAccount: Account? {
        accounts.first(where: { $0.id == activeAccountId })
    }
    
    func addAccount(_ account: Account) {
        accounts.append(account)
        saveAccounts()
        if accounts.count == 1 {
            activeAccountId = account.id
        }
    }
    
    func deleteAccount(_ id: String) {
        accounts.removeAll(where: { $0.id == id })
        if activeAccountId == id {
            activeAccountId = accounts.first?.id ?? ""
        }
        saveAccounts()
    }
    
    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }
}
