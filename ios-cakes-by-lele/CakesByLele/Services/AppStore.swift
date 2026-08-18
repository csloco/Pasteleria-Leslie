import Foundation
import Observation

nonisolated struct AppData: Codable, Sendable {
    var recipes: [Recipe] = []
    var inventory: [InventoryItem] = []
    var orders: [Order] = []
    var clients: [Client] = []
    var catalog: [CatalogProduct] = []
    var savedCalculations: [SavedCalculation] = []
    var expenses: Double = 0
    var chefName: String = "Lele"
    var defaultUnit: LengthUnit = .inches
    var defaultServingSize: ServingSize = .normal
    var defaultWastePercent: Double = 0.10
    var roundEggs: Bool = true
    var markupMultiplier: Double = 3.2

    static func seeded() -> AppData {
        var data = AppData()
        data.inventory = SeedData.makeInventory()
        data.recipes = SeedData.makeRecipes(inventory: data.inventory)
        data.orders = SeedData.makeOrders(recipes: data.recipes, inventory: data.inventory)
        data.clients = SeedData.makeClients(from: data.orders)
        data.catalog = SeedData.makeCatalog()
        data.expenses = 4260
        return data
    }
}

/// Single source of truth for the whole app, persisted as JSON in the documents folder.
@Observable
final class AppStore {
    var data: AppData {
        didSet { scheduleSave() }
    }

    private var saveTask: Task<Void, Never>?

    private static var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("cakes-by-lele.json")
    }

    init() {
        if let stored = AppStore.load() {
            data = stored
        } else {
            data = AppData.seeded()
            scheduleSave()
        }
    }

    // MARK: - Persistence

    private static func load() -> AppData? {
        guard let raw = try? Data(contentsOf: fileURL) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AppData.self, from: raw)
        } catch {
            print("[AppStore] No se pudo leer la información guardada, se usará contenido inicial.")
            return nil
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = data
        saveTask = Task { [snapshot] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            AppStore.write(snapshot)
        }
    }

    private static func write(_ snapshot: AppData) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted]
            let encoded = try encoder.encode(snapshot)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            print("[AppStore] No se pudo guardar la información.")
        }
    }

    func resetToSeed() {
        data = AppData.seeded()
    }

    // MARK: - Derived collections

    var todayOrders: [Order] {
        data.orders.filter { Calendar.app.isDateInToday($0.deliveryDate) && $0.status != .cancelado }
            .sorted { $0.deliveryDate < $1.deliveryDate }
    }

    var upcomingOrders: [Order] {
        let now = Date()
        return data.orders
            .filter { $0.deliveryDate > now && !Calendar.app.isDateInToday($0.deliveryDate) && $0.status.isOpen }
            .sorted { $0.deliveryDate < $1.deliveryDate }
    }

    var pendingConfirmation: [Order] {
        data.orders.filter { $0.status == .consulta || $0.status == .cotizacion || $0.status == .esperandoAnticipo }
    }

    var pendingPayment: [Order] {
        data.orders.filter { $0.status.isOpen && $0.balance > 0 }
    }

    var productionOrders: [Order] {
        data.orders.filter { $0.status.isProduction }
            .sorted { $0.deliveryDate < $1.deliveryDate }
    }

    var todayProductionOrders: [Order] {
        let list = productionOrders.filter { Calendar.app.isDateInToday($0.deliveryDate) }
        return list.isEmpty ? productionOrders : list
    }

    var lowStockItems: [InventoryItem] {
        data.inventory.filter(\.isLow).sorted { $0.name < $1.name }
    }

    var monthSales: Double {
        let now = Date()
        return data.orders
            .filter { Calendar.app.isDate($0.deliveryDate, equalTo: now, toGranularity: .month) && $0.status != .cancelado }
            .reduce(0) { $0 + $1.price + $1.shippingCost }
    }

    var monthExpenses: Double { data.expenses }
    var monthProfit: Double { monthSales - monthExpenses }

    func orders(on date: Date) -> [Order] {
        data.orders
            .filter { Calendar.app.isDate($0.deliveryDate, inSameDayAs: date) && $0.status != .cancelado }
            .sorted { $0.deliveryDate < $1.deliveryDate }
    }

    func recipe(id: UUID?) -> Recipe? {
        guard let id else { return nil }
        return data.recipes.first { $0.id == id }
    }

    var defaultRecipe: Recipe? { data.recipes.first }

    func calculate(spec: CakeSpec, recipeID: UUID?) -> CalculationResult {
        let recipe = recipe(id: recipeID) ?? defaultRecipe
        return CakeCalculator.calculate(spec: spec,
                                        defaultRecipe: recipe,
                                        recipes: data.recipes,
                                        inventory: data.inventory)
    }

    // MARK: - Mutations

    func upsert(order: Order) {
        if let index = data.orders.firstIndex(where: { $0.id == order.id }) {
            data.orders[index] = order
        } else {
            data.orders.append(order)
        }
        registerClientIfNeeded(from: order)
    }

    func deleteOrder(id: UUID) {
        data.orders.removeAll { $0.id == id }
    }

    private func registerClientIfNeeded(from order: Order) {
        guard !order.clientName.isEmpty else { return }
        if let index = data.clients.firstIndex(where: { $0.name.localizedCaseInsensitiveCompare(order.clientName) == .orderedSame }) {
            if data.clients[index].instagram.isEmpty { data.clients[index].instagram = order.instagram }
            if data.clients[index].phone.isEmpty { data.clients[index].phone = order.phone }
        } else {
            data.clients.append(Client(name: order.clientName,
                                       instagram: order.instagram,
                                       phone: order.phone,
                                       favoriteFlavor: order.flavor))
        }
    }

    func upsert(item: InventoryItem) {
        if let index = data.inventory.firstIndex(where: { $0.id == item.id }) {
            data.inventory[index] = item
        } else {
            data.inventory.append(item)
        }
    }

    func deleteInventory(id: UUID) {
        data.inventory.removeAll { $0.id == id }
    }

    func upsert(recipe: Recipe) {
        if let index = data.recipes.firstIndex(where: { $0.id == recipe.id }) {
            data.recipes[index] = recipe
        } else {
            data.recipes.append(recipe)
        }
    }

    func deleteRecipe(id: UUID) {
        data.recipes.removeAll { $0.id == id }
    }

    func upsert(client: Client) {
        if let index = data.clients.firstIndex(where: { $0.id == client.id }) {
            data.clients[index] = client
        } else {
            data.clients.append(client)
        }
    }

    func upsert(product: CatalogProduct) {
        if let index = data.catalog.firstIndex(where: { $0.id == product.id }) {
            data.catalog[index] = product
        } else {
            data.catalog.append(product)
        }
    }

    /// Regenerates the automatic materials of an order, keeping manual ones untouched.
    func refreshProductionTicket(orderID: UUID) {
        guard let index = data.orders.firstIndex(where: { $0.id == orderID }) else { return }
        var order = data.orders[index]
        let recipe = recipe(id: order.recipeID) ?? defaultRecipe
        let result = calculate(spec: order.spec, recipeID: order.recipeID)
        let manual = order.materials.filter { !$0.isAutomatic }
        let readyByName = Dictionary(order.materials.map { ($0.name.lowercased(), $0.isReady) },
                                     uniquingKeysWith: { first, _ in first })
        var generated = CakeCalculator.materials(from: result, spec: order.spec, recipeName: recipe?.name ?? "pastel")
        for i in generated.indices {
            generated[i].isReady = readyByName[generated[i].name.lowercased()] ?? false
        }
        order.materials = generated + manual
        if order.checklist.isEmpty {
            order.checklist = CakeCalculator.checklist(from: result, spec: order.spec)
        }
        data.orders[index] = order
    }

    /// Subtracts every ready material from the pantry stock.
    func deductInventory(orderID: UUID) {
        guard let orderIndex = data.orders.firstIndex(where: { $0.id == orderID }) else { return }
        let materials = data.orders[orderIndex].materials
        for material in materials {
            let itemIndex: Int?
            if let id = material.inventoryItemID {
                itemIndex = data.inventory.firstIndex { $0.id == id }
            } else {
                itemIndex = data.inventory.firstIndex {
                    $0.name.localizedCaseInsensitiveCompare(material.name) == .orderedSame
                }
            }
            guard let index = itemIndex, data.inventory[index].unit == material.unit else { continue }
            data.inventory[index].stock = max(data.inventory[index].stock - material.quantity, 0)
        }
        data.orders[orderIndex].inventoryDeducted = true
    }

    /// Sums the ingredients of several orders and compares them with the current stock.
    func shoppingList(for orders: [Order]) -> [ShoppingLine] {
        var totals: [String: ShoppingLine] = [:]
        for order in orders {
            let recipe = recipe(id: order.recipeID) ?? defaultRecipe
            let result = CakeCalculator.calculate(spec: order.spec,
                                                  defaultRecipe: recipe,
                                                  recipes: data.recipes,
                                                  inventory: data.inventory)
            for ingredient in result.ingredients {
                let key = ingredient.name.lowercased()
                let stockItem = data.inventory.first {
                    $0.id == ingredient.inventoryItemID || $0.name.localizedCaseInsensitiveCompare(ingredient.name) == .orderedSame
                }
                var line = totals[key] ?? ShoppingLine(id: ingredient.id,
                                                       name: ingredient.name,
                                                       unit: ingredient.unit,
                                                       needed: 0,
                                                       available: stockItem?.stock ?? 0,
                                                       pricePerUnit: stockItem?.pricePerUnit ?? 0)
                line.needed += ingredient.quantity
                totals[key] = line
            }
        }
        return totals.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

nonisolated struct ShoppingLine: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var unit: MeasureUnit
    var needed: Double
    var available: Double
    var pricePerUnit: Double

    var toBuy: Double { max(needed - available, 0) }
    var estimatedCost: Double { toBuy * pricePerUnit }
    var isCovered: Bool { toBuy <= 0.001 }
}
