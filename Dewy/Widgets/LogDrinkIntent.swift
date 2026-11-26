import AppIntents
import WidgetKit

/// Logs a drink straight from a widget button, Shortcuts or Siri.
/// Shared by the app and the widget extension; both write to the App Group container.
struct LogDrinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a drink"

    @Parameter(title: "Drink", default: .water)
    var drink: DrinkKind

    @Parameter(title: "Amount (ml)", default: 250)
    var amount: Double

    init() {}

    init(kind: DrinkKind, amount: Double) {
        self.drink = kind
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        let persistence = Persistence()
        var data = persistence.load() ?? AppData()
        data.entries.append(DrinkEntry(date: .now, amount: amount, kind: drink))
        persistence.save(data)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

extension DrinkKind: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Drink"

    static let caseDisplayRepresentations: [DrinkKind: DisplayRepresentation] = [
        .water: "Water",
        .sparkling: "Sparkling",
        .tea: "Tea",
        .coffee: "Coffee",
        .juice: "Juice",
        .milk: "Milk",
        .smoothie: "Smoothie",
        .soda: "Soda",
        .lemonade: "Lemonade",
        .cocoa: "Hot Cocoa",
        .coconut: "Coconut",
        .matcha: "Matcha"
    ]
}
