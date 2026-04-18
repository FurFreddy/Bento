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
                
                List {
                    // --- SEKTION: ACCOUNTS ---
                    Section(header: Text("ACCOUNTS").foregroundColor(theme.current.cMuted)) {
                        ForEach(store.accounts) { acc in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(acc.name)
                                        .foregroundColor(theme.current.cTextMain)
                                        .fontWeight(store.activeAccountId == acc.id ? .bold : .regular)
                                    Text(acc.domain.replacingOccurrences(of: "https://", with: ""))
                                        .font(.caption)
                                        .foregroundColor(theme.current.cMuted)
                                }
                                Spacer()
                                if store.activeAccountId == acc.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.current.cAccent)
                                }
                                Button { editingAccount = acc } label: {
                                    Image(systemName: "pencil.circle")
                                        .foregroundColor(theme.current.cAccent)
                                }
                                .buttonStyle(.plain)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                store.activeAccountId = acc.id
                            }
                        }
                        .listRowBackground(theme.current.cBgSub)
                        
                        Button(action: { showingAddAccount = true }) {
                            Label("Konto hinzufügen", systemImage: "plus.circle.fill")
                                .foregroundColor(theme.current.cAccent)
                        }
                        .listRowBackground(theme.current.cBgSub)
                    }
                    
                    // --- SEKTION: APPEARANCE ---
                    Section(header: Text("APPEARANCE").foregroundColor(theme.current.cMuted)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Themes").font(.caption.bold())
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(theme.baseThemes) { t in
                                        ThemePreview(theme: t, isSelected: theme.selectedThemeId == t.id) {
                                            theme.setTheme(t)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listRowBackground(theme.current.cBgSub)
                    }
                    
                    // --- SEKTION: LAYOUT & INTERFACE ---
                    Section(header: Text("LAYOUT & INTERFACE").foregroundColor(theme.current.cMuted)) {
                        Picker("Preview Quality", selection: $store.previewQuality) {
                            Text("Low").tag("low")
                            Text("Medium").tag("medium")
                            Text("High").tag("high")
                        }
                        Toggle("Seitenzahlen anzeigen", isOn: $store.showPageNumbers)
                    }
                    .listRowBackground(theme.current.cBgSub)
                    .foregroundColor(theme.current.cTextMain)
                    
                    // --- SEKTION: CONTENT (SAFE MODE) ---
                    Section(header: Text("CONTENT & ZENSUR").foregroundColor(theme.current.cMuted)) {
                        Toggle("Safe Mode Aktiv", isOn: $store.safeMode)
                        
                        if store.safeMode {
                            Picker("Level", selection: $store.safeModeLevel) {
                                Text("Strict").tag("strict")
                                Text("Normal").tag("normal")
                            }
                            Picker("Aktion", selection: $store.safeModeAction) {
                                Text("Verschwimmen").tag("blur")
                                Text("Verstecken").tag("hide")
                            }
                            if store.safeModeAction == "blur" {
                                VStack(alignment: .leading) {
                                    Text("Unschärfe-Stärke: \(Int(store.safeModeBlurStrength))")
                                    Slider(value: $store.safeModeBlurStrength, in: 5...50, step: 1)
                                }
                            }
                        }
                    }
                    .listRowBackground(theme.current.cBgSub)
                    .foregroundColor(theme.current.cTextMain)
                    
                    // --- SEKTION: DATA & INFO ---
                    Section(header: Text("DATA & INFO").foregroundColor(theme.current.cMuted)) {
                        Button("Cache leeren") {
                            // URLCache.shared.removeAllCachedResponses()
                        }
                        Button("Daten Exportieren (JSON)") {
                            // Export Logik
                        }
                    }
                    .listRowBackground(theme.current.cBgSub)
                    .foregroundColor(theme.current.cTextMain)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(theme.current.cAccent)
                        .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .sheet(item: $editingAccount) { acc in
                EditAccountView(account: acc)
            }
        }
    }
}