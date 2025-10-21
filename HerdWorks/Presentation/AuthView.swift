//
//  AuthView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var vm: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showPasswordResetSuccess = false

    var body: some View {
        VStack(spacing: 16) {
            Text("auth.app_title".localized())
                .font(.system(size: 48, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: $vm.mode) {
                Text("auth.sign_in".localized()).tag(AuthViewModel.Mode.signIn)
                Text("auth.sign_up".localized()).tag(AuthViewModel.Mode.signUp)
            }
            .pickerStyle(.segmented)

            TextField("auth.email".localized(), text: $vm.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("auth.password".localized(), text: $vm.password)
                .textFieldStyle(.roundedBorder)

            Button(vm.mode == .signIn ? "auth.sign_in".localized() : "auth.sign_up".localized()) {
                Task {
                    if vm.mode == .signIn { await vm.signIn() }
                    else { await vm.signUp() }
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(vm.isBusy || vm.email.isEmpty || vm.password.isEmpty)

            Button("auth.forgot_password".localized()) {
                Task {
                    print("🔄 User tapped forgot password for email: \(vm.email)")
                    await vm.resetPassword()
                    if vm.errorMessage == nil {
                        print("✅ Password reset completed without error")
                        showPasswordResetSuccess = true
                    } else {
                        print("❌ Password reset failed with error: \(vm.errorMessage ?? "unknown")")
                    }
                }
            }
            .disabled(vm.isBusy || vm.email.isEmpty)
            .foregroundColor(vm.email.isEmpty ? .gray : .blue)
            
            if vm.email.isEmpty {
                Text("auth.enter_email_prompt".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let err = vm.errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if let user = vm.currentUser {
                VStack(spacing: 8) {
                    Text(String(format: "auth.logged_in_as".localized(), user.email ?? user.uid))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("auth.sign_out".localized()) { vm.signOut() }
                }
            }
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("auth.password_reset_sent_title".localized(), isPresented: $showPasswordResetSuccess) {
            Button("common.ok".localized(), role: .cancel) { }
        } message: {
            Text(String(format: "auth.password_reset_sent_message".localized(), vm.email))
        }
    }
}

#Preview {
    AuthView(vm: AuthViewModel(repo: FirebaseAuthRepository()))
        .environmentObject(LanguageManager.shared)
}
