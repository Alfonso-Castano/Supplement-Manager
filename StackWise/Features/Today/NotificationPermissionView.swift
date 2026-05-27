import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    var onComplete: () -> Void
    @Environment(ScheduleStore.self) private var scheduleStore

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.aquaPrimary)
                    .padding(.top, 24)

                Text("Never Miss a Dose")
                    .font(.swTitle1)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Get a reminder at the right time for each block in your schedule.")
                    .font(.swBody)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(icon: "clock.fill",
                               text: "Timed to your morning, afternoon, and evening blocks")
                    BenefitRow(icon: "list.bullet",
                               text: "Each reminder lists your specific supplements")
                    BenefitRow(icon: "bell.slash",
                               text: "You control notifications any time in Settings")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 48)
        }
        .background(Color.backgroundPage.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button("Enable Reminders") {
                    Task {
                        try? await UNUserNotificationCenter.current()
                            .requestAuthorization(options: [.alert, .sound, .badge])
                        // Schedule immediately after auth — notifications were skipped during
                        // onboarding because permission hadn't been granted yet.
                        NotificationScheduler.reschedule(for: scheduleStore.currentSchedule())
                        onComplete()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.aquaPrimary)
                .font(.swHeadline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .background(Color.backgroundPage)
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.aquaPrimary)
                .frame(width: 24)
            Text(text)
                .font(.swBody)
                .foregroundStyle(.textPrimary)
        }
    }
}
