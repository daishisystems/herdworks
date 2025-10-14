//
//  AuthView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//


import SwiftUI

struct AuthView: View {
    @ObservedObject var vm: AuthViewModel

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
                Task { await vm.resetPassword() }
            }
            .disabled(vm.isBusy || vm.email.isEmpty)

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
    }
}

#Preview {
    AuthView(vm: AuthViewModel(repo: FirebaseAuthRepository()))
}
