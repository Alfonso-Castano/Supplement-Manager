import SwiftUI

/// Stub: Plan 06-03 replaces this with the full permission-gate UI.
struct NotificationPermissionView: View {
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(.aquaPrimary)

            Text("Never Miss a Dose")
                .font(.title.bold())

            Text("Enable reminders to stay on track.")
                .foregroundStyle(.secondary)

            Button("Enable Reminders") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .tint(.aquaPrimary)
        }
        .padding()
    }
}
