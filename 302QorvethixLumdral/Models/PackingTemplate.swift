import Foundation

struct PackingTemplate: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let items: [(title: String, category: TripItemCategory)]

    static let all: [PackingTemplate] = [
        PackingTemplate(
            id: "beach",
            title: "Beach",
            detail: "Sun, sand, light pack",
            icon: "sun.max.fill",
            items: [
                ("Swimsuit", .clothing),
                ("Sunglasses", .essentials),
                ("Sunscreen", .essentials),
                ("Flip-flops", .clothing),
                ("Beach towel", .essentials),
                ("Hat", .clothing),
                ("Passport", .essentials),
                ("Phone charger", .essentials)
            ]
        ),
        PackingTemplate(
            id: "winter",
            title: "Winter",
            detail: "Cold weather essentials",
            icon: "snowflake",
            items: [
                ("Winter coat", .clothing),
                ("Thermal layers", .clothing),
                ("Gloves", .clothing),
                ("Scarf", .clothing),
                ("Boots", .clothing),
                ("Moisturizer", .essentials),
                ("Passport", .essentials),
                ("Power bank", .essentials)
            ]
        ),
        PackingTemplate(
            id: "business",
            title: "Business",
            detail: "Meetings and travel days",
            icon: "briefcase.fill",
            items: [
                ("Suit / blazer", .clothing),
                ("Dress shoes", .clothing),
                ("Laptop", .essentials),
                ("Chargers", .essentials),
                ("Business cards", .essentials),
                ("Documents folder", .essentials),
                ("Toiletry kit", .essentials),
                ("Passport", .essentials)
            ]
        )
    ]
}
