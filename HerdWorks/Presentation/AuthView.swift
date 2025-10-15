//
//  AuthView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//


import SwiftUI

struct AuthView: View {
    @ObservedObject var vm: AuthViewModel
    @State private var showPasswordResetSuccess = false

    var body: some View {
        VStack(spacing: 16) {
            Text("HerdWorks")
                .font(.system(size: 48, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: $vm.mode) {
                Text("Sign In").tag(AuthViewModel.Mode.signIn)
                Text("Sign Up").tag(AuthViewModel.Mode.signUp)
            }
            .pickerStyle(.segmented)

            TextField("Email", text: $vm.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $vm.password)
                .textFieldStyle(.roundedBorder)

            Button(vm.mode == .signIn ? "Sign In" : "Sign Up") {
                Task {
                    if vm.mode == .signIn { await vm.signIn() }
                    else { await vm.signUp() }
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(vm.isBusy || vm.email.isEmpty || vm.password.isEmpty)

            Button("Forgot password?") {
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
                Text("Enter your email address above to reset password")
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
                    Text("Logged in as: \(user.email ?? user.uid)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Sign Out") { vm.signOut() }
                }
            }
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("Password Reset Sent", isPresented: $showPasswordResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A password reset link has been sent to \(vm.email). Check your email and follow the instructions to reset your password.")
        }
    }
}

#Preview {
    AuthView(vm: AuthViewModel(repo: FirebaseAuthRepository()))
}
