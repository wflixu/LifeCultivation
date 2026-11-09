import SwiftUI

struct CalorieRingCard: View {
    let record: DailyRecord
    let profile: UserProfile?
    let showNutritionDetail: Binding<Bool>

    // MARK: - Computed properties

    private var tdee: Double { record.effectiveTDEE(profile: profile) }
    private var intake: Double { record.totalIntake }
    private var exercise: Double { record.exerciseCalories }
    private var burned: Double { tdee + exercise }
    private var remaining: Double { burned - intake }

    private var totalCarbs: Double {
        (record.foods ?? []).reduce(0.0) { $0 + ($1.carbs ?? 0) }
    }
    private var totalProtein: Double {
        (record.foods ?? []).reduce(0.0) { $0 + ($1.protein ?? 0) }
    }
    private var totalFat: Double {
        (record.foods ?? []).reduce(0.0) { $0 + ($1.fat ?? 0) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            calorieRow
            macroRow
        }
        .padding(20)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
    }

    // MARK: - Row 1: 已摄入 | 半圆环(文字在内) | 已消耗

    private var calorieRow: some View {
        HStack(alignment: .center, spacing: 0) {
            intakeBlock
            Spacer()
            halfRingBlock
            Spacer()
            burnedBlock
        }
    }

    // MARK: Left — Intake

    private var intakeBlock: some View {
        VStack(spacing: 4) {
            Text("\(Int(intake))")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(intake > burned && burned > 0 ? AppColors.accentRed : .primary)
            Text("已摄入 kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 72)
    }

    // MARK: Center — Half Ring with text inside

    private var halfRingBlock: some View {
        let isOver = remaining < 0 && burned > 0
        let ratio: CGFloat = {
            if burned <= 0 { return 0 }
            let r = max(0, remaining / burned)
            return min(r, 1)
        }()

        return ZStack {
            // Background track — top half
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(
                    isOver ? AppColors.accentRed.opacity(0.15) : Color(.systemGray5),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))

            // Foreground — fills from left to right
            Circle()
                .trim(from: 0, to: (isOver ? 0.5 : ratio * 0.5))
                .stroke(
                    isOver ? AnyShapeStyle(overageGradient) : AnyShapeStyle(halfRingGradient),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))
                .animation(.easeInOut(duration: 0.8), value: ratio)
                .shadow(color: (isOver ? AppColors.accentRed : AppColors.primary).opacity(isOver ? 0.5 : 0.2),
                        radius: isOver ? 8 : 4, y: 2)

            // Text inside the semicircle
            VStack(spacing: 2) {
                Text(isOver ? "+\(Int(abs(remaining)))" : "\(Int(max(0, remaining)))")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(isOver ? AppColors.accentRed : .primary)
                Text(isOver ? "超标 kcal" : "剩余 kcal")
                    .font(.caption)
                    .foregroundStyle(isOver ? AppColors.accentRed : .secondary)
            }
        }
        .frame(width: 140, height: 90)
    }

    private var halfRingGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                AppColors.primary,
                AppColors.primary.opacity(0.6)
            ]),
            center: .center,
            startAngle: .degrees(180),
            endAngle: .degrees(360)
        )
    }

    private var overageGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                AppColors.accentRed,
                AppColors.accentRed.opacity(0.7)
            ]),
            center: .center,
            startAngle: .degrees(180),
            endAngle: .degrees(360)
        )
    }

    // MARK: Right — Burned

    private var burnedBlock: some View {
        VStack(spacing: 4) {
            Text("\(Int(burned))")
                .font(.system(.title2, design: .rounded).weight(.bold))
            Text("已消耗 kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 72)
    }

    // MARK: - Row 2: 碳水 | 蛋白质 | 脂肪

    private var macroRow: some View {
        let totalBurned = record.effectiveTDEE(profile: profile) + record.exerciseCalories
        let carbTarget = totalBurned > 0 ? totalBurned * 0.50 / 4 : 0
        let proteinTarget = totalBurned > 0 ? totalBurned * 0.25 / 4 : 0
        let fatTarget = totalBurned > 0 ? totalBurned * 0.25 / 9 : 0

        return HStack(spacing: 10) {
            macroItem(label: "碳水", actual: totalCarbs, target: carbTarget, color: .blue)
            macroItem(label: "蛋白质", actual: totalProtein, target: proteinTarget, color: .red)
            macroItem(label: "脂肪", actual: totalFat, target: fatTarget, color: .yellow)
        }
    }

    private func macroItem(label: String, actual: Double, target: Double, color: Color) -> some View {
        let pct: CGFloat = target > 0 ? min(actual / target, 1.2) : 0
        let isOver = actual > target && target > 0

        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(isOver ? AppColors.accentRed : color)
                        .frame(width: max(geo.size.width * pct, pct > 0 ? 4 : 0), height: 6)
                        .animation(.easeInOut(duration: 0.6), value: actual)
                }
            }
            .frame(height: 6)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(actual))")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(isOver ? AppColors.accentRed : .primary)
                Text("/")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(Int(target))g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}
