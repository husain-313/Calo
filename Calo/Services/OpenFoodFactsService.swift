import Foundation

/// Client for the free Open Food Facts API (barcode lookup + text search).
/// No API key required. Nutrition is normalized to per-100 g/ml.
struct OpenFoodFactsService {

    enum OFFError: Error { case notFound, badResponse }

    private let session: URLSession
    private let userAgent = "Calo/0.1 (personal use)"

    init(session: URLSession = .shared) { self.session = session }

    // MARK: Barcode

    func lookup(barcode: String) async throws -> FoodItem {
        let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw OFFError.badResponse }
        let decoded = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        guard decoded.status == 1, let p = decoded.product else { throw OFFError.notFound }
        return p.toFoodItem(barcode: barcode)
    }

    // MARK: Search

    func search(_ query: String, page: Int = 1) async throws -> [FoodItem] {
        var comps = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        comps.queryItems = [
            .init(name: "search_terms", value: query),
            .init(name: "search_simple", value: "1"),
            .init(name: "action", value: "process"),
            .init(name: "json", value: "1"),
            .init(name: "page_size", value: "40"),
            .init(name: "page", value: String(page)),
            .init(name: "fields", value: "code,product_name,brands,nutriments,serving_quantity,serving_size")
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw OFFError.badResponse }
        let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        return decoded.products.compactMap { p in
            guard let name = p.product_name, !name.isEmpty else { return nil }
            return p.toFoodItem(barcode: p.code)
        }
    }
}

// MARK: - Wire types

private struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]
}

private struct OFFProduct: Decodable {
    let code: String?
    let product_name: String?
    let brands: String?
    let serving_quantity: OFFNumber?
    let serving_size: String?
    let nutriments: OFFNutriments?

    func toFoodItem(barcode: String?) -> FoodItem {
        let n = nutriments
        var servings: [ServingSize] = [.hundred]
        if let sq = serving_quantity?.value, sq > 0 {
            servings.insert(ServingSize(label: serving_size ?? "1 serving", amountInBase: sq), at: 0)
        }
        return FoodItem(
            name: product_name ?? "Unknown",
            brand: brands,
            barcode: barcode,
            source: "openfoodfacts",
            caloriesPer100: n?.energyKcal100 ?? 0,
            proteinPer100: n?.proteins100 ?? 0,
            carbsPer100: n?.carbs100 ?? 0,
            fatPer100: n?.fat100 ?? 0,
            fiberPer100: n?.fiber100 ?? 0,
            sugarPer100: n?.sugars100 ?? 0,
            sodiumPer100: (n?.sodium100 ?? 0) * 1000, // g -> mg
            saturatedFatPer100: n?.saturatedFat100 ?? 0,
            baseUnit: "g",
            servings: servings
        )
    }
}

/// OFF nutriment fields that may arrive as String or Number.
private struct OFFNumber: Decodable {
    let value: Double?
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { value = d }
        else if let s = try? c.decode(String.self) { value = Double(s) }
        else { value = nil }
    }
}

private struct OFFNutriments: Decodable {
    let energyKcal100: Double?
    let proteins100: Double?
    let carbs100: Double?
    let fat100: Double?
    let fiber100: Double?
    let sugars100: Double?
    let sodium100: Double?
    let saturatedFat100: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100 = "energy-kcal_100g"
        case proteins100 = "proteins_100g"
        case carbs100 = "carbohydrates_100g"
        case fat100 = "fat_100g"
        case fiber100 = "fiber_100g"
        case sugars100 = "sugars_100g"
        case sodium100 = "sodium_100g"
        case saturatedFat100 = "saturated-fat_100g"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func num(_ k: CodingKeys) -> Double? {
            if let d = try? c.decode(Double.self, forKey: k) { return d }
            if let s = try? c.decode(String.self, forKey: k) { return Double(s) }
            return nil
        }
        energyKcal100 = num(.energyKcal100)
        proteins100 = num(.proteins100)
        carbs100 = num(.carbs100)
        fat100 = num(.fat100)
        fiber100 = num(.fiber100)
        sugars100 = num(.sugars100)
        sodium100 = num(.sodium100)
        saturatedFat100 = num(.saturatedFat100)
    }
}
