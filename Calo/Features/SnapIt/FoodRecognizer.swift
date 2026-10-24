import Foundation
#if canImport(Vision)
import Vision
#endif
#if canImport(UIKit)
import UIKit
#endif

/// A recognized food candidate from an image.
struct FoodGuess: Identifiable, Hashable {
    let id = UUID()
    let label: String        // human label, e.g. "Banana"
    let confidence: Double    // 0...1
}

/// On-device food recognition using Apple's Vision image classifier.
/// No external model, no network, no API key. A Core ML food model can be
/// dropped in later via `classifyWithCoreML` without changing the UI.
enum FoodRecognizer {

    #if canImport(Vision) && canImport(UIKit)
    static func classify(_ image: UIImage) async -> [FoodGuess] {
        guard let cg = image.cgImage else { return [] }
        return await withCheckedContinuation { cont in
            let request = VNClassifyImageRequest { req, _ in
                let obs = (req.results as? [VNClassificationObservation]) ?? []
                let guesses = rank(obs)
                cont.resume(returning: guesses)
            }
            let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(image), options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) }
                catch { cont.resume(returning: []) }
            }
        }
    }

    /// Keep plausible food labels, prefer known food terms, drop noise.
    private static func rank(_ obs: [VNClassificationObservation]) -> [FoodGuess] {
        let scored = obs
            .filter { $0.confidence > 0.03 }
            .map { FoodGuess(label: prettify($0.identifier), confidence: Double($0.confidence)) }

        let foods = scored.filter { isLikelyFood($0.label) }
        let base = foods.isEmpty ? scored : foods
        // De-duplicate by label, keep highest confidence, cap the list.
        var seen = Set<String>()
        return base
            .sorted { $0.confidence > $1.confidence }
            .filter { seen.insert($0.label.lowercased()).inserted }
            .prefix(8)
            .map { $0 }
    }

    private static func prettify(_ id: String) -> String {
        id.replacingOccurrences(of: "_", with: " ")
          .split(separator: ",").first.map(String.init)?
          .trimmingCharacters(in: .whitespaces)
          .capitalized ?? id.capitalized
    }

    private static func cgOrientation(_ image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
    #else
    static func classify(_ image: Any) async -> [FoodGuess] { [] }
    #endif

    /// Heuristic food filter over Vision's taxonomy labels.
    static func isLikelyFood(_ label: String) -> Bool {
        let l = label.lowercased()
        if foodKeywords.contains(where: { l.contains($0) }) { return true }
        if nonFoodKeywords.contains(where: { l.contains($0) }) { return false }
        return false
    }

    private static let foodKeywords: Set<String> = [
        "food", "fruit", "vegetable", "meat", "fish", "seafood", "bread", "cake",
        "pastry", "dessert", "pizza", "burger", "sandwich", "salad", "soup", "rice",
        "pasta", "noodle", "egg", "cheese", "chicken", "beef", "pork", "lamb",
        "banana", "apple", "orange", "grape", "berry", "strawberry", "mango",
        "pineapple", "melon", "peach", "pear", "lemon", "lime", "avocado", "tomato",
        "potato", "carrot", "broccoli", "corn", "bean", "pea", "onion", "pepper",
        "cucumber", "lettuce", "spinach", "mushroom", "nut", "almond", "peanut",
        "chocolate", "cookie", "biscuit", "donut", "muffin", "pie", "ice cream",
        "yogurt", "milk", "juice", "coffee", "tea", "smoothie", "cereal", "oat",
        "pancake", "waffle", "taco", "burrito", "sushi", "steak", "bacon", "sausage",
        "shrimp", "salmon", "tuna", "curry", "stew", "dumpling", "fries", "snack",
        "drink", "beverage", "wrap", "bagel", "croissant", "honey", "jam", "butter",
        "popcorn", "pretzel", "candy", "date", "fig", "plum", "cherry", "kiwi",
        "coconut", "lentil", "chickpea", "hummus", "guacamole", "omelet", "quiche",
        "meal", "dish", "plate", "bowl"
    ]

    private static let nonFoodKeywords: Set<String> = [
        "person", "people", "face", "animal", "dog", "cat", "furniture", "vehicle",
        "car", "building", "structure", "plant", "tree", "flower", "text", "document",
        "screen", "device", "electronics", "clothing", "landscape", "sky", "water body"
    ]
}
