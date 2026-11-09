import SwiftUI
import UIKit

/// A food row that supports swipe-to-delete and works inside both a
/// horizontally-paging ScrollView and the vertical card ScrollView.
///
/// The swipe uses a pan recognizer that only claims clearly horizontal drags.
/// A plain `DragGesture` (even with a direction check in `onChanged`) claims
/// every drag once it recognizes, which steals vertical drags from the
/// enclosing ScrollView and makes scrolling over the list feel unresponsive.
struct SwipeableFoodRow: View {
    let food: FoodEntry
    let onTap: () -> Void
    let onDeleteRequest: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0

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
                .gesture(
                    HorizontalPanGesture(
                        onBegan: {
                            dragStartOffset = dragOffset
                        },
                        onChanged: { translation in
                            let raw = dragStartOffset + translation
                            if raw < -deleteButtonWidth {
                                // Rubber-band past the fully revealed position.
                                dragOffset = -deleteButtonWidth + (raw + deleteButtonWidth) * 0.3
                            } else {
                                dragOffset = min(0, max(-deleteButtonWidth, raw))
                            }
                        },
                        onEnded: { _, predicted in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = predicted < swipeThreshold ? -deleteButtonWidth : 0
                            }
                        }
                    )
                )
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
            dragStartOffset = 0
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

}

// MARK: - Horizontal-only pan gesture

/// A pan recognizer that only begins for horizontal drags, so vertical drags
/// fall through to the enclosing ScrollView.
private final class HorizontalPanRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let translation = translation(in: view)
        let velocity = velocity(in: view)
        let horizontal = abs(translation.x) + abs(velocity.x)
        let vertical = abs(translation.y) + abs(velocity.y)
        return horizontal > 0 && horizontal > vertical
    }
}

private struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    var onBegan: () -> Void
    var onChanged: (CGFloat) -> Void
    /// (translation, predicted end translation)
    var onEnded: (CGFloat, CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> HorizontalPanRecognizer {
        HorizontalPanRecognizer()
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: HorizontalPanRecognizer,
        context: Context
    ) {
        let translation = recognizer.translation(in: recognizer.view).x
        let velocity = recognizer.velocity(in: recognizer.view).x
        switch recognizer.state {
        case .began:
            onBegan()
        case .changed:
            onChanged(translation)
        case .ended, .cancelled, .failed:
            // Same intent as DragGesture.predictedEndTranslation.
            onEnded(translation, translation + velocity * 0.2)
        default:
            break
        }
    }
}
