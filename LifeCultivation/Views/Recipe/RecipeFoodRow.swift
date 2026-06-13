import SwiftUI

struct RecipeFoodRow: View {
    let food: FavoriteFood

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.subheadline.weight(.medium))
                Text(food.serving)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(food.calories)) kcal")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
