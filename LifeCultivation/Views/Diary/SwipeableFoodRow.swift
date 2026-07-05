import SwiftUI

/// A food row that supports swipe-to-delete with highPriorityGesture
/// to work correctly inside a horizontally-paging ScrollView.
struct SwipeableFoodRow: View {
    let food: FoodEntry
    let onTap: () -> Void
    let onDeleteRequest: () -> Void

    @State private var dragOffset: CGFloat = 0

    private let deleteButtonWidth: CGFloat = 72
    private let swipeThreshold: CGFloat = -40

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button revealed behind the row
            deleteButton
                .opacity(dragOffset < -10 ? 1 : 0)

            // Main row content
            rowContent
                .background(AppColors.cardBackground)
                .offset(x: dragOffset)
                .highPriorityGesture(swipeGesture)
                .onTapGesture {
                    if dragOffset < 0 {
                        // If swiped open, tap to close
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    } else {
                        onTap()
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        onDeleteRequest()
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
        }
        .clipped()
        .onChange(of: food.id) { _, _ in
            // Reset offset when food changes
            dragOffset = 0
        }
    }

    // MARK: - Row Content

    private var rowContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                Text(food.serving)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(food.calories)) kcal")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .padding(.leading, 48)
        .contentShape(.rect)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(role: .destructive) {
            Haptic.medium()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = 0
            }
            onDeleteRequest()
        } label: {
            Image(systemName: "trash")
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: deleteButtonWidth)
                .frame(maxHeight: .infinity)
                .background(.red)
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Only allow horizontal (leftward) drags that are more horizontal than vertical
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard isHorizontal else { return }

                let newOffset = min(0, max(-deleteButtonWidth, value.translation.width))
                // Add resistance if already past threshold
                if newOffset < swipeThreshold && dragOffset < swipeThreshold {
                    let overscroll = newOffset - swipeThreshold
                    dragOffset = swipeThreshold + overscroll * 0.3
                } else {
                    dragOffset = newOffset
                }
            }
            .onEnded { value in
                let predictedEnd = value.predictedEndTranslation.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if predictedEnd < swipeThreshold {
                        dragOffset = -deleteButtonWidth
                    } else {
                        dragOffset = 0
                    }
                }
            }
    }
}
