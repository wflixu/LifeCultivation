import SwiftUI

struct StreakCard: View {
    let recordingStreak: Int
    let goalMetStreak: Int

    var body: some View {
        HStack(spacing: 0) {
            streakItem(
                emoji: "🔥",
                count: goalMetStreak,
                label: "连续未超目标"
            )

            Divider().frame(height: 50)

            streakItem(
                emoji: "📝",
                count: recordingStreak,
                label: "连续记录"
            )
        }
        .padding(20)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
    }

    private func streakItem(emoji: String, count: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.title2)
            Text("\(count)")
                .font(.system(.title, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
