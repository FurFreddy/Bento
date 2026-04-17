import SwiftUI

struct SettingsView: View {
    @ObservedObject var store = SettingsStore.shared
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingAddAccount = false
    @State private var editingAccount: Account?
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.current.cBgMain.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // --- THEME PICKER ---
                        VStack(alignment: .leading, spacing: 18) {
                            
                            // BASE THEMES
                            VStack(alignment: .leading, spacing: 8) {
                                Text("BASE THEMES")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(theme.current.cMuted)
                                    .padding(.horizontal, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(theme.baseThemes) { t in
                                            ThemePreview(theme: t, isSelected: theme.selectedThemeId == t.id) {
                                                withAnimation { theme.setTheme(t) }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // PRIDE THEMES
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PRIDE THEMES")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(theme.current.cMuted)
                                    .padding(.horizontal, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(theme.prideThemes) { t in
                                            ThemePreview(theme: t, isSelected: theme.selectedThemeId == t.id) {
                                                withAnimation { theme.setTheme(t) }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // --- CATEGORIES ---
                        VStack(spacing: 0) {
                            SettingsCategoryRow(title: "Appearance", icon: "paintpalette")
                            SettingsCategoryRow(title: "Layout & Interface", icon: "square.grid.2x2")
                            SettingsCategoryRow(title: "Safe Mode", icon: "shield")
                        }
                        .background(theme.current.cBgSub)
                        .cornerRadius(15)
                        
                        // --- ACCOUNTS SECTION ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACCOUNTS")
                                .font(.caption.bold())
                                .foregroundColor(theme.current.cMuted)
                                .padding(.horizontal, 4)
                            
                            ForEach(store.accounts) { account in
                                AccountRow(account: account, isActive: store.activeAccountId == account.id) {
                                    store.activeAccountId = account.id
                                } onEdit: {
                                    editingAccount = account
                                }
                            }
                            
                            Button {
                                showingAddAccount = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Account")
                                    Spacer()
                                }
                                .padding()
                                .background(theme.current.cBgSub)
                                .foregroundColor(theme.current.cAccent)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.current.cAccent)
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .sheet(item: $editingAccount) { account in
                EditAccountView(account: account)
            }
        }
        .navigationViewStyle(.stack)
    }
}

// Subviews (ThemePreview, SettingsCategoryRow, AccountRow, etc) remain similar...
struct ThemePreview: View {
    let theme: AppTheme
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(theme.cBgMain)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(theme.cAccent)
                    .frame(width: 25, height: 25)
                    .offset(x: 10, y: 10)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? theme.cAccent : Color.clear, lineWidth: 3)
                    .scaleEffect(1.2)
            )
            
            Text(theme.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isSelected ? theme.cAccent : .gray)
        }
        .padding(.vertical, 10)
        .onTapGesture {
            action()
        }
    }
}

struct SettingsCategoryRow: View {
    @ObservedObject var theme = ThemeManager.shared
    let title: String
    let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(theme.current.cAccent)
            Text(title)
                .foregroundColor(theme.current.cTextMain)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.current.cMuted)
        }
        .padding()
        Divider().background(theme.current.cBgMain).padding(.leading, 50)
    }
}

struct AccountRow: View {
    @ObservedObject var theme = ThemeManager.shared
    let account: Account
    let isActive: Bool
    var onSelect: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundColor(isActive ? theme.current.cAccent : theme.current.cMuted)
                .frame(width: 40, height: 40)
                .background(theme.current.cBgMain)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                    .foregroundColor(theme.current.cTextMain)
                Text(account.username.isEmpty ? "Guest" : account.username)
                    .font(.caption)
                    .foregroundColor(theme.current.cMuted)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.current.cAccent)
            }
            
            Button { onEdit() } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(theme.current.cMuted)
            }
        }
        .padding()
        .background(theme.current.cBgSub)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isActive ? theme.current.cAccent : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct AddAccountView: View {
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            theme.current.cBgMain.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("CHOOSE A TEMPLATE")
                        .font(.caption.bold())
                        .foregroundColor(theme.current.cMuted)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(BOORU_TEMPLATES) { tmpl in
                            Button {
                                let acc = Account(name: tmpl.name, type: tmpl.type, domain: tmpl.domain)
                                SettingsStore.shared.addAccount(acc)
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    Text(tmpl.name).bold()
                                    Text(tmpl.domain.replacingOccurrences(of: "https://", with: ""))
                                        .font(.caption2)
                                        .opacity(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.current.cBgSub)
                                .foregroundColor(theme.current.cTextMain)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

struct EditAccountView: View {
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @State var account: Account
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.current.cBgMain.ignoresSafeArea()
                Form {
                    Section("Identity") {
                        TextField("Name", text: $account.name)
                        TextField("Domain", text: $account.domain)
                    }
                    Section("Library") {
                        TextField("Username", text: $account.username)
                        SecureField("API Key / Password", text: $account.apiKey)
                    }
                    
                    Button("Delete Account", role: .destructive) {
                        SettingsStore.shared.deleteAccount(account.id)
                        dismiss()
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        SettingsStore.shared.updateAccount(account)
                        dismiss()
                    }
                    .foregroundColor(theme.current.cAccent)
                }
            }
        }
    }
}
