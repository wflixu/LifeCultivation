import SwiftUI

struct StreakCard: View {
    let recordingStreak: Int
    let goalMetStreak: Int

    var body: some View {
        HStack(spacing: 0) {
            streakItem(
                icon: "flame.fill",
                iconColor: .orange,
                count: goalMetStreak,
                label: "连续未超目标"
            )

            Divider().frame(height: 50)

            streakItem(
                icon: "calendar.badge.checkmark",
                iconColor: .blue,
                count: recordingStreak,
                label: "连续记录"
            )
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func streakItem(icon: String, iconColor: Color, count: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text("\(count)")
                .font(.system(.title, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
