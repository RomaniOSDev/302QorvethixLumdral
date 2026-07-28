import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Food"
    case transport = "Transport"
    case lodging = "Lodging"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "tram.fill"
        case .lodging: return "bed.double.fill"
        case .other: return "cart.fill"
        }
    }
}

struct TripExpense: Identifiable, Codable, Equatable {
    var id: String
    var category: ExpenseCategory
    var amount: Double
    var note: String

    init(
        id: String = UUID().uuidString,
        category: ExpenseCategory,
        amount: Double,
        note: String = ""
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.note = note
    }
}

struct Trip: Identifiable, Codable, Equatable {
    var id: String
    var destination: String
    var country: String
    var date: Date
    var note: String
    var visited: Bool
    var expenses: [TripExpense]
    var photoFileNames: [String]

    init(
        id: String = UUID().uuidString,
        destination: String,
        country: String,
        date: Date,
        note: String,
        visited: Bool = false,
        expenses: [TripExpense] = [],
        photoFileNames: [String] = []
    ) {
        self.id = id
        self.destination = destination
        self.country = country
        self.date = date
        self.note = note
        self.visited = visited
        self.expenses = expenses
        self.photoFileNames = photoFileNames
    }

    var budgetTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    enum CodingKeys: String, CodingKey {
        case id, destination, country, date, note, visited
        case expenses, photoFileNames
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        destination = try c.decode(String.self, forKey: .destination)
        country = try c.decode(String.self, forKey: .country)
        date = try c.decode(Date.self, forKey: .date)
        note = try c.decode(String.self, forKey: .note)
        visited = try c.decode(Bool.self, forKey: .visited)
        expenses = try c.decodeIfPresent([TripExpense].self, forKey: .expenses) ?? []
        photoFileNames = try c.decodeIfPresent([String].self, forKey: .photoFileNames) ?? []
    }
}

enum BudgetFormat {
    static func string(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
}
