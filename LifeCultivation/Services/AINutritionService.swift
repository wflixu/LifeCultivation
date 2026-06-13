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

// MARK: - Protocol

protocol NutritionServiceProtocol: Sendable {
    func recognizeFood(description: String, imageData: Data?) async throws -> [RecognizedFood]
    func suggestNutrition(foodName: String, serving: String) async throws -> [NutritionSuggestion]
}

// MARK: - Implementation

final class AINutritionService: NutritionServiceProtocol {
    private let apiKey: String
    private let baseURL: String
    private let model: String

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    init(apiKey: String, baseURL: String? = nil, model: String = "claude-sonnet-4-6") {
        self.apiKey = apiKey
        self.baseURL = baseURL ?? "https://api.anthropic.com"
        self.model = model
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

    // MARK: - Private

    private func makeRequest(body: [String: Any]) async throws -> Data {
        let url = URL(string: "\(baseURL)/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
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
            food.calories > 0 &&
            food.calories < 3000 &&
            (food.protein ?? 0) >= 0 &&
            (food.fat ?? 0) >= 0 &&
            (food.carbs ?? 0) >= 0 &&
            !food.name.trimmingCharacters(in: .whitespaces).isEmpty
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

// MARK: - Error

enum NutritionError: Error, LocalizedError {
    case apiError
    case invalidResponse
    case networkError

    var errorDescription: String? {
        switch self {
        case .apiError: "AI 服务请求失败，请检查 API Key"
        case .invalidResponse: "AI 返回数据异常，请重试"
        case .networkError: "网络连接失败，请检查网络"
        }
    }
}
