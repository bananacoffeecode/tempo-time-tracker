import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) var viewModel
    @State private var confirmingDisconnect = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.6)
            content
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.dismissSettings()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(TempoIconButtonStyle())

            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            PanelCloseButton()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {

            sectionHeader("Account")

            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Google Calendar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(viewModel.authManager.userEmail.isEmpty ? "—" : viewModel.authManager.userEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 14))
                    .help("Connected")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: Metrics.cardCorner, style: .continuous)
                    .fill(.primary.opacity(0.04))
            }
            .padding(.horizontal, 16)

            disconnectRow
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private var disconnectRow: some View {
        Group {
            if confirmingDisconnect {
                VStack(spacing: 8) {
                    Text("Disconnect Google Calendar?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button("Cancel") {
                            confirmingDisconnect = false
                        }
                        .buttonStyle(TempoLinkButtonStyle())
                        .frame(maxWidth: .infinity)

                        Button("Disconnect") {
                            viewModel.signOut()
                        }
                        .buttonStyle(TempoPrimaryButtonStyle(tint: .red))
                        .frame(maxWidth: .infinity)
                    }
                }
                .transition(.opacity.combined(with: .offset(y: 6)))
            } else {
                Button {
                    confirmingDisconnect = true
                } label: {
                    Label("Disconnect Calendar", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
                .buttonStyle(TempoLinkButtonStyle(color: .red))
                .transition(.opacity)
            }
        }
        .animation(.tempoSpring, value: confirmingDisconnect)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }
}
