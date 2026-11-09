import Foundation

// MARK: - DTOs

struct RecognizedFood: Codable, Sendable {
    let name: String
    let serving: String
    let calories: Double
    let protein: Double?
    let fat: Double?
    let carbs: Double?
}

struct NutritionSuggestion: Codable, Sendable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let reasoning: String
}

// MARK: - DTOs

struct ExerciseCalorieEstimation: Codable, Sendable {
    let calories: Double
    let reasoning: String
}

// MARK: - Protocol

@MainActor
protocol NutritionServiceProtocol: Sendable {
    func recognizeFood(description: String, imageData: Data?) async throws -> [RecognizedFood]
    func suggestNutrition(foodName: String, serving: String) async throws -> [NutritionSuggestion]
    func estimateExerciseCalories(description: String) async throws -> Double
}

// MARK: - Implementation

@MainActor
final class AINutritionService: NutritionServiceProtocol {
    private let profile: UserProfile
    private let defaultAPIKey: String
    private let defaultBaseURL: String
    private let defaultModel: String

    private var apiKey: String {
        let stored = profile.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return stored.isEmpty ? defaultAPIKey : stored
    }

    private var baseURL: String {
        let stored = profile.apiBaseURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !stored.isEmpty { return stored }
        return defaultBaseURL.isEmpty ? "https://api.anthropic.com" : defaultBaseURL
    }

    private var model: String {
        let stored = profile.aiModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return stored.isEmpty ? defaultModel : stored
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    init(
        profile: UserProfile,
        defaultAPIKey: String = "",
        defaultBaseURL: String = "",
        defaultModel: String = "claude-sonnet-4-6"
    ) {
        self.profile = profile
        self.defaultAPIKey = defaultAPIKey
        self.defaultBaseURL = defaultBaseURL
        self.defaultModel = defaultModel
    }

    func recognizeFood(description: String, imageData: Data? = nil) async throws -> [RecognizedFood] {
        let systemPrompt = """
        你是一个专业的营养师，擅长估算中餐的热量和营养成分。

        规则：
        1. 根据用户描述的食物名称和份量，估算热量(kcal)和三大宏量营养素(蛋白质protein、脂肪fat、碳水化合物carbs，单位均为克)
        2. 以中国常见份量为基准，例如：
           - 一碗米饭≈150g≈174kcal，蛋白质3g，脂肪0.4g，碳水39g
           - 一个鸡蛋≈50g≈72kcal，蛋白质6g，脂肪5g，碳水0.7g
           - 一杯牛奶≈250ml≈155kcal，蛋白质8g，脂肪8g，碳水12g
           - 中杯可乐≈400ml≈170kcal，蛋白质0g，脂肪0g，碳水42g
        3. 如果用户描述了份量，请尊重用户的描述；否则按常规一人份估算
        4. 严格返回以下 JSON 格式，不要包含任何其他文字：
        {
          "foods": [
            {"name": "食物名", "serving": "份量", "calories": 0, "protein": 0, "fat": 0, "carbs": 0}
          ]
        }
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "stream": false,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "请识别以下食物：\(description)"]
            ]
        ]

        let data = try await makeRequest(body: requestBody)
        let response = try decoder.decode(FoodRecognitionResponse.self, from: data)
        let textBlock = response.content.first { $0.type == "text" && $0.text != nil }
        guard let text = textBlock?.text else {
            throw NutritionError.invalidResponse
        }
        return try parseFoodJSON(text)
    }

    func suggestNutrition(foodName: String, serving: String) async throws -> [NutritionSuggestion] {
        let systemPrompt = """
        你是一个专业营养师。用户需要编辑"\(foodName)"（\(serving)）的营养成分。
        请给出 2-3 组合理的热量和营养估算值，严格返回以下 JSON 格式，不要包含任何其他文字：
        {
          "suggestions": [
            {"calories": 0, "protein": 0, "fat": 0, "carbs": 0, "reasoning": "估算依据"}
          ]
        }
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "stream": false,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "请为「\(foodName)」提供营养成分建议"]
            ]
        ]

        let data = try await makeRequest(body: requestBody)
        let response = try decoder.decode(SuggestionResponse.self, from: data)
        let textBlock = response.content.first { $0.type == "text" && $0.text != nil }
        guard let text = textBlock?.text else {
            throw NutritionError.invalidResponse
        }
        let suggestionData = text.data(using: .utf8)!
        let wrapper = try decoder.decode(SuggestionWrapper.self, from: suggestionData)
        return wrapper.suggestions
    }

    func estimateExerciseCalories(description: String) async throws -> Double {
        let systemPrompt = """
        你是一个专业的运动生理学家，擅长估算各类运动的能量消耗。

        规则：
        1. 根据用户提供的运动类型、时长和强度描述，估算消耗的卡路里(kcal)
        2. 参考标准 MET 值，但要根据用户描述的强度进行调整：
           - 低强度/轻松 ≈ MET * 0.7-0.8
           - 中等强度/正常 ≈ MET * 1.0
           - 高强度/剧烈/出了很多汗 ≈ MET * 1.2-1.5
        3. 常见运动 MET 参考值：
           - 跑步: 7-12 (慢跑~7, 中速~9, 快跑~12)
           - 骑行: 4-10 (休闲~4, 中速~7, 快速~10)
           - 游泳: 5-10
           - 步行: 2-4
           - 力量训练: 4-6
           - 有氧体操: 5-8
           - 球类运动: 5-10
        4. 以一个 70kg 的成年人为基准估算
        5. 严格返回以下 JSON 格式，不要包含任何其他文字：
        {
          "calories": 0,
          "reasoning": "估算依据简述"
        }
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 256,
            "stream": false,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "请估算以下运动的卡路里消耗：\(description)"]
            ]
        ]

        let data = try await makeRequest(body: requestBody)
        let response = try decoder.decode(ExerciseEstimationResponse.self, from: data)
        let textBlock = response.content.first { $0.type == "text" && $0.text != nil }
        guard let text = textBlock?.text else {
            throw NutritionError.invalidResponse
        }
        return try parseExerciseJSON(text)
    }

    private func parseExerciseJSON(_ text: String) throws -> Double {
        if let data = text.data(using: .utf8),
           let estimation = try? decoder.decode(ExerciseCalorieEstimation.self, from: data) {
            guard estimation.calories > 0, estimation.calories < 5000 else {
                throw NutritionError.invalidResponse
            }
            return estimation.calories
        }

        // Fallback: extract JSON from markdown code blocks
        if let match = text.range(of: "```(?:json)?\\s*\\n?([\\s\\S]*?)```", options: .regularExpression) {
            let jsonStr = String(text[match]).replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = jsonStr.data(using: .utf8),
               let estimation = try? decoder.decode(ExerciseCalorieEstimation.self, from: data),
               estimation.calories > 0, estimation.calories < 5000 {
                return estimation.calories
            }
        }

        // Try to find JSON-like content
        if let braceRange = text.range(of: "\\{[\\s\\S]*\"calories\"[\\s\\S]*\\}", options: .regularExpression) {
            let jsonStr = String(text[braceRange])
            if let data = jsonStr.data(using: .utf8),
               let estimation = try? decoder.decode(ExerciseCalorieEstimation.self, from: data),
               estimation.calories > 0, estimation.calories < 5000 {
                return estimation.calories
            }
        }

        throw NutritionError.invalidResponse
    }

    // MARK: - Private

    private func makeRequest(body: [String: Any]) async throws -> Data {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw NutritionError.missingAPIKey }

        let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmedBaseURL.hasSuffix("/")
            ? String(trimmedBaseURL.dropLast())
            : trimmedBaseURL
        guard let url = URL(string: "\(base)/v1/messages") else {
            throw NutritionError.apiError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NutritionError.apiError
        }

        return data
    }

    private func parseFoodJSON(_ text: String) throws -> [RecognizedFood] {
        // Try direct JSON decode first
        if let data = text.data(using: .utf8),
           let wrapper = try? decoder.decode(FoodWrapper.self, from: data) {
            return validate(wrapper.foods)
        }

        // Fallback: extract JSON from markdown code blocks
        if let match = text.range(of: "```(?:json)?\\s*\\n?([\\s\\S]*?)```", options: .regularExpression) {
            let jsonStr = String(text[match]).replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = jsonStr.data(using: .utf8),
               let wrapper = try? decoder.decode(FoodWrapper.self, from: data) {
                return validate(wrapper.foods)
            }
        }

        // Try to find JSON-like content
        if let braceRange = text.range(of: "\\{[\\s\\S]*\"foods\"[\\s\\S]*\\}", options: .regularExpression) {
            let jsonStr = String(text[braceRange])
            if let data = jsonStr.data(using: .utf8),
               let wrapper = try? decoder.decode(FoodWrapper.self, from: data) {
                return validate(wrapper.foods)
            }
        }

        throw NutritionError.invalidResponse
    }

    func validate(_ foods: [RecognizedFood]) -> [RecognizedFood] {
        foods.filter { food in
            let macroCals = (food.protein ?? 0) * 4 + (food.fat ?? 0) * 9 + (food.carbs ?? 0) * 4
            let discrepancy = macroCals > 0 ? abs(food.calories - macroCals) / max(macroCals, food.calories) : 0
            return food.calories > 0 &&
                food.calories < 3000 &&
                (food.protein ?? 0) >= 0 &&
                (food.fat ?? 0) >= 0 &&
                (food.carbs ?? 0) >= 0 &&
                !food.name.trimmingCharacters(in: .whitespaces).isEmpty &&
                (macroCals == 0 || discrepancy < 0.5) // macros vs calories discrepancy < 50%
        }
    }
}

// MARK: - Response types

private struct FoodRecognitionResponse: Codable {
    let content: [ContentBlock]
}

private struct ContentBlock: Codable {
    let text: String?
    let type: String
}

private struct FoodWrapper: Codable {
    let foods: [RecognizedFood]
}

private struct SuggestionResponse: Codable {
    let content: [ContentBlock]
}

private struct SuggestionWrapper: Codable {
    let suggestions: [NutritionSuggestion]
}

private struct ExerciseEstimationResponse: Codable {
    let content: [ContentBlock]
}

// MARK: - Error

enum NutritionError: Error, LocalizedError {
    case apiError
    case invalidResponse
    case networkError
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .apiError: "AI 服务请求失败，请检查 API Key"
        case .invalidResponse: "AI 返回数据异常，请重试"
        case .networkError: "网络连接失败，请检查网络"
        case .missingAPIKey: "请先在个人资料中配置 API Key"
        }
    }
}
