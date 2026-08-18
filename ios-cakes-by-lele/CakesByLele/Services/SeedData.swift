import Foundation

/// Realistic starting content so the app is useful from the first launch.
nonisolated enum SeedData {
    static func makeInventory() -> [InventoryItem] {
        [
            InventoryItem(name: "Harina", category: .harinas, unit: .gram, stock: 2000, minimumStock: 500, packageQuantity: 2000, packagePrice: 24, packageLabel: "Bolsa de 2,000 g"),
            InventoryItem(name: "Azúcar", category: .azucares, unit: .gram, stock: 3400, minimumStock: 800, packageQuantity: 2000, packagePrice: 20, packageLabel: "Bolsa de 2,000 g"),
            InventoryItem(name: "Huevos", category: .lacteos, unit: .unit, stock: 30, minimumStock: 12, packageQuantity: 30, packagePrice: 60, packageLabel: "Cartón de 30"),
            InventoryItem(name: "Mantequilla", category: .lacteos, unit: .gram, stock: 1800, minimumStock: 500, packageQuantity: 500, packagePrice: 25, packageLabel: "Barra de 500 g"),
            InventoryItem(name: "Leche", category: .lacteos, unit: .milliliter, stock: 2000, minimumStock: 500, packageQuantity: 1000, packagePrice: 12, packageLabel: "Litro"),
            InventoryItem(name: "Vainilla", category: .otros, unit: .milliliter, stock: 220, minimumStock: 60, packageQuantity: 120, packagePrice: 28, packageLabel: "Frasco de 120 ml"),
            InventoryItem(name: "Polvo de hornear", category: .harinas, unit: .gram, stock: 380, minimumStock: 100, packageQuantity: 200, packagePrice: 14, packageLabel: "Bote de 200 g"),
            InventoryItem(name: "Cocoa", category: .chocolates, unit: .gram, stock: 900, minimumStock: 250, packageQuantity: 500, packagePrice: 42, packageLabel: "Bolsa de 500 g"),
            InventoryItem(name: "Chocolate", category: .chocolates, unit: .gram, stock: 1800, minimumStock: 600, packageQuantity: 1000, packagePrice: 85, packageLabel: "Barra de 1,000 g"),
            InventoryItem(name: "Crema para batir", category: .lacteos, unit: .milliliter, stock: 1500, minimumStock: 500, packageQuantity: 1000, packagePrice: 38, packageLabel: "Litro"),
            InventoryItem(name: "Fondant", category: .decoracion, unit: .gram, stock: 1200, minimumStock: 400, packageQuantity: 1000, packagePrice: 70, packageLabel: "Bolsa de 1,000 g"),
            InventoryItem(name: "Colorantes", category: .decoracion, unit: .unit, stock: 8, minimumStock: 3, packageQuantity: 1, packagePrice: 18, packageLabel: "Frasco"),
            InventoryItem(name: "Cajas de 8\"", category: .empaque, unit: .unit, stock: 4, minimumStock: 6, packageQuantity: 10, packagePrice: 90, packageLabel: "Paquete de 10"),
            InventoryItem(name: "Bases doradas", category: .empaque, unit: .unit, stock: 12, minimumStock: 6, packageQuantity: 10, packagePrice: 65, packageLabel: "Paquete de 10")
        ]
    }

    static func makeRecipes(inventory: [InventoryItem]) -> [Recipe] {
        func id(_ name: String) -> UUID? { inventory.first { $0.name == name }?.id }

        let vanilla = Recipe(
            name: "Vainilla",
            emoji: "🍰",
            shape: .round,
            panPrimarySize: 6,
            referenceSpongeHeight: 4,
            yieldGrams: 950,
            ingredients: [
                RecipeIngredient(name: "Harina", quantity: 300, unit: .gram, inventoryItemID: id("Harina")),
                RecipeIngredient(name: "Azúcar", quantity: 250, unit: .gram, inventoryItemID: id("Azúcar")),
                RecipeIngredient(name: "Huevos", quantity: 4, unit: .unit, inventoryItemID: id("Huevos")),
                RecipeIngredient(name: "Mantequilla", quantity: 200, unit: .gram, inventoryItemID: id("Mantequilla")),
                RecipeIngredient(name: "Leche", quantity: 180, unit: .milliliter, inventoryItemID: id("Leche")),
                RecipeIngredient(name: "Vainilla", quantity: 10, unit: .milliliter, inventoryItemID: id("Vainilla")),
                RecipeIngredient(name: "Polvo de hornear", quantity: 8, unit: .gram, inventoryItemID: id("Polvo de hornear"))
            ],
            procedure: "Cremar mantequilla con azúcar, incorporar huevos uno a uno, alternar secos con leche y hornear hasta que el palillo salga limpio.",
            ovenTemperature: 175,
            bakeMinutes: 35,
            notes: "Rinde tres bizcochos de 2\" en molde de 6\"."
        )

        let chocolate = Recipe(
            name: "Chocolate",
            emoji: "🍫",
            shape: .round,
            panPrimarySize: 6,
            referenceSpongeHeight: 4,
            yieldGrams: 1000,
            ingredients: [
                RecipeIngredient(name: "Harina", quantity: 280, unit: .gram, inventoryItemID: id("Harina")),
                RecipeIngredient(name: "Cocoa", quantity: 70, unit: .gram, inventoryItemID: id("Cocoa")),
                RecipeIngredient(name: "Azúcar", quantity: 300, unit: .gram, inventoryItemID: id("Azúcar")),
                RecipeIngredient(name: "Huevos", quantity: 4, unit: .unit, inventoryItemID: id("Huevos")),
                RecipeIngredient(name: "Mantequilla", quantity: 210, unit: .gram, inventoryItemID: id("Mantequilla")),
                RecipeIngredient(name: "Leche", quantity: 200, unit: .milliliter, inventoryItemID: id("Leche")),
                RecipeIngredient(name: "Polvo de hornear", quantity: 9, unit: .gram, inventoryItemID: id("Polvo de hornear"))
            ],
            procedure: "Mezclar secos, integrar húmedos y hornear en moldes engrasados.",
            ovenTemperature: 175,
            bakeMinutes: 38,
            notes: "Ideal con ganache."
        )

        let redVelvet = Recipe(
            name: "Red Velvet",
            emoji: "❤️",
            shape: .round,
            panPrimarySize: 6,
            referenceSpongeHeight: 4,
            yieldGrams: 930,
            ingredients: [
                RecipeIngredient(name: "Harina", quantity: 310, unit: .gram, inventoryItemID: id("Harina")),
                RecipeIngredient(name: "Azúcar", quantity: 260, unit: .gram, inventoryItemID: id("Azúcar")),
                RecipeIngredient(name: "Huevos", quantity: 3, unit: .unit, inventoryItemID: id("Huevos")),
                RecipeIngredient(name: "Mantequilla", quantity: 190, unit: .gram, inventoryItemID: id("Mantequilla")),
                RecipeIngredient(name: "Leche", quantity: 190, unit: .milliliter, inventoryItemID: id("Leche")),
                RecipeIngredient(name: "Cocoa", quantity: 15, unit: .gram, inventoryItemID: id("Cocoa")),
                RecipeIngredient(name: "Colorantes", quantity: 1, unit: .unit, inventoryItemID: id("Colorantes"))
            ],
            procedure: "Integrar colorante con los húmedos antes de unir con secos.",
            ovenTemperature: 170,
            bakeMinutes: 32,
            notes: "Acompañar con buttercream de queso crema."
        )

        let tresLeches = Recipe(
            name: "Tres leches",
            emoji: "🥛",
            shape: .round,
            panPrimarySize: 8,
            referenceSpongeHeight: 3,
            yieldGrams: 1100,
            ingredients: [
                RecipeIngredient(name: "Harina", quantity: 320, unit: .gram, inventoryItemID: id("Harina")),
                RecipeIngredient(name: "Azúcar", quantity: 240, unit: .gram, inventoryItemID: id("Azúcar")),
                RecipeIngredient(name: "Huevos", quantity: 5, unit: .unit, inventoryItemID: id("Huevos")),
                RecipeIngredient(name: "Leche", quantity: 400, unit: .milliliter, inventoryItemID: id("Leche")),
                RecipeIngredient(name: "Crema para batir", quantity: 250, unit: .milliliter, inventoryItemID: id("Crema para batir"))
            ],
            procedure: "Hornear bizcocho esponjoso y bañar con la mezcla de leches en frío.",
            ovenTemperature: 180,
            bakeMinutes: 30,
            notes: "Dejar reposar 4 horas antes de decorar."
        )

        return [vanilla, chocolate, redVelvet, tresLeches]
    }

    static func makeOrders(recipes: [Recipe], inventory: [InventoryItem]) -> [Order] {
        let calendar = Calendar.app
        let today = Date()

        func at(_ dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        func tier(_ size: Double, layers: Int, layerHeight: Double, filling: FillingKind, thickness: Double, recipeID: UUID?) -> CakeTier {
            var t = CakeTier()
            t.primarySize = size
            t.recipeID = recipeID
            t.layers = (0..<layers).map { _ in SpongeLayer(height: layerHeight) }
            t.fillings = (0..<max(layers - 1, 0)).map { _ in FillingLayer(kind: filling, thickness: thickness) }
            return t
        }

        let chocolateID = recipes.first { $0.name == "Chocolate" }?.id
        let vanillaID = recipes.first { $0.name == "Vainilla" }?.id
        let redVelvetID = recipes.first { $0.name == "Red Velvet" }?.id
        let tresLechesID = recipes.first { $0.name == "Tres leches" }?.id

        var orders: [Order] = []

        var maria = Order(clientName: "María López",
                          instagram: "@marialopez",
                          phone: "5512 3344",
                          createdAt: at(-3, hour: 10),
                          deliveryDate: at(0, hour: 15),
                          status: .porPreparar,
                          cakeTitle: "Chocolate 8\"",
                          flavor: "Chocolate",
                          recipeID: chocolateID,
                          design: "Buttercream rosa empolvado con flores naturales",
                          dedication: "Feliz cumpleaños, Sofía",
                          price: 420,
                          deposit: 420,
                          address: "Zona 10, Ciudad",
                          shippingCost: 35,
                          notes: "Entregar antes de las 3:30 PM.")
        maria.spec.tiers = [tier(8, layers: 3, layerHeight: 2, filling: .chocolate, thickness: 0.5, recipeID: chocolateID)]
        orders.append(maria)

        var ana = Order(clientName: "Ana Pérez",
                        instagram: "@anaperez",
                        phone: "4455 8899",
                        createdAt: at(-2, hour: 11),
                        deliveryDate: at(0, hour: 17, minute: 30),
                        status: .esperandoAnticipo,
                        cakeTitle: "Red Velvet 6\"",
                        flavor: "Red Velvet",
                        recipeID: redVelvetID,
                        design: "Cobertura lisa blanca con detalles dorados",
                        dedication: "Con cariño",
                        price: 300,
                        deposit: 120,
                        address: "Zona 15, Ciudad",
                        shippingCost: 30)
        ana.spec.tiers = [tier(6, layers: 3, layerHeight: 2, filling: .buttercream, thickness: 0.5, recipeID: redVelvetID)]
        orders.append(ana)

        var carlaM = Order(clientName: "Carla Méndez",
                           instagram: "@carlamendez",
                           phone: "3322 1100",
                           createdAt: at(-4, hour: 9),
                           deliveryDate: at(0, hour: 16),
                           status: .confirmado,
                           cakeTitle: "Cheesecake 7\"",
                           flavor: "Cheesecake",
                           recipeID: vanillaID,
                           design: "Cheesecake con frutos rojos",
                           price: 350,
                           deposit: 350)
        carlaM.spec.tiers = [tier(7, layers: 1, layerHeight: 2.5, filling: .fresa, thickness: 0.5, recipeID: vanillaID)]
        orders.append(carlaM)

        var julio = Order(clientName: "Julio Vásquez",
                          instagram: "@juliovg",
                          phone: "5566 7788",
                          createdAt: at(-1, hour: 13),
                          deliveryDate: at(0, hour: 18),
                          status: .decorando,
                          cakeTitle: "Tres Leches 9\"",
                          flavor: "Tres leches",
                          recipeID: tresLechesID,
                          design: "Merengue y duraznos",
                          price: 480,
                          deposit: 480)
        julio.spec.tiers = [tier(9, layers: 2, layerHeight: 2, filling: .crema, thickness: 0.75, recipeID: tresLechesID)]
        orders.append(julio)

        var carlaR = Order(clientName: "Carla Ruiz",
                           instagram: "@carlaruiz",
                           phone: "7788 1122",
                           createdAt: at(-1, hour: 12, minute: 30),
                           deliveryDate: at(4, hour: 14),
                           status: .cotizacion,
                           cakeTitle: "Pastel de vainilla de 2 pisos",
                           flavor: "Vainilla",
                           recipeID: vanillaID,
                           design: "Dos pisos con flores de fondant",
                           price: 780,
                           deposit: 0)
        carlaR.spec.tiers = [
            tier(6, layers: 3, layerHeight: 2, filling: .ganache, thickness: 0.5, recipeID: vanillaID),
            tier(8, layers: 3, layerHeight: 2, filling: .dulceDeLeche, thickness: 0.75, recipeID: vanillaID)
        ]
        orders.append(carlaR)

        var lucia = Order(clientName: "Lucía Barrios",
                          instagram: "@luciabarrios",
                          phone: "2233 4455",
                          createdAt: at(-1, hour: 9),
                          deliveryDate: at(6, hour: 15),
                          status: .consulta,
                          cakeTitle: "Naked Cake 6\"",
                          flavor: "Vainilla",
                          recipeID: vanillaID,
                          design: "Naked cake con frutas",
                          price: 320)
        lucia.spec.tiers = [tier(6, layers: 3, layerHeight: 2, filling: .crema, thickness: 0.5, recipeID: vanillaID)]
        orders.append(lucia)

        var sofia = Order(clientName: "Sofía Orellana",
                          instagram: "@sofiaorellana",
                          phone: "9988 7766",
                          createdAt: at(-2, hour: 16),
                          deliveryDate: at(4, hour: 14),
                          status: .confirmado,
                          cakeTitle: "Brownies (24 uds.)",
                          flavor: "Chocolate",
                          recipeID: chocolateID,
                          design: "Brownies individuales empacados",
                          price: 260,
                          deposit: 260)
        sofia.spec.tiers = [tier(9, layers: 1, layerHeight: 1.5, filling: .chocolate, thickness: 0.25, recipeID: chocolateID)]
        orders.append(sofia)

        var previous = Order(clientName: "María López",
                             instagram: "@marialopez",
                             phone: "5512 3344",
                             createdAt: at(-25, hour: 10),
                             deliveryDate: at(-18, hour: 15),
                             status: .entregado,
                             cakeTitle: "Vainilla 8\"",
                             flavor: "Vainilla",
                             recipeID: vanillaID,
                             price: 400,
                             deposit: 400)
        previous.spec.tiers = [tier(8, layers: 3, layerHeight: 2, filling: .buttercream, thickness: 0.5, recipeID: vanillaID)]
        orders.append(previous)

        // Pre-fill production data for orders already in the kitchen.
        return orders.map { order in
            var copy = order
            guard copy.status.isProduction else { return copy }
            let recipe = recipes.first { $0.id == copy.recipeID }
            let result = CakeCalculator.calculate(spec: copy.spec,
                                                  defaultRecipe: recipe,
                                                  recipes: recipes,
                                                  inventory: inventory)
            copy.materials = CakeCalculator.materials(from: result, spec: copy.spec, recipeName: recipe?.name ?? "pastel")
            copy.checklist = CakeCalculator.checklist(from: result, spec: copy.spec)
            if copy.status == .decorando || copy.status == .horneado {
                for index in copy.checklist.indices.prefix(4) { copy.checklist[index].isDone = true }
                for index in copy.materials.indices.prefix(3) { copy.materials[index].isReady = true }
            }
            return copy
        }
    }

    static func makeClients(from orders: [Order]) -> [Client] {
        var seen: [String: Client] = [:]
        for order in orders where !order.clientName.isEmpty {
            if seen[order.clientName] == nil {
                seen[order.clientName] = Client(name: order.clientName,
                                                instagram: order.instagram,
                                                phone: order.phone,
                                                favoriteFlavor: order.flavor)
            }
        }
        return seen.values.sorted { $0.name < $1.name }
    }

    static func makeCatalog() -> [CatalogProduct] {
        [
            CatalogProduct(name: "Pastel personalizado", category: .personalizados, detail: "Diseño a medida con flores y topper", basePrice: 450, sizes: "6\", 8\", 10\"", flavors: "Vainilla, Chocolate, Red Velvet", servings: 20),
            CatalogProduct(name: "Clásico de chocolate", category: .clasicos, detail: "Bizcocho de chocolate con ganache", basePrice: 380, sizes: "6\", 8\"", flavors: "Chocolate", servings: 16),
            CatalogProduct(name: "Cupcakes decorados", category: .cupcakes, detail: "Caja de 12 unidades", basePrice: 180, sizes: "Caja de 6 o 12", flavors: "Vainilla, Chocolate", servings: 12),
            CatalogProduct(name: "Mini cake para dos", category: .miniCakes, detail: "Pastel de 4\" ideal para regalo", basePrice: 150, sizes: "4\"", flavors: "Vainilla, Red Velvet", servings: 4),
            CatalogProduct(name: "Tres leches familiar", category: .postres, detail: "Postre frío en molde rectangular", basePrice: 320, sizes: "9×13\"", flavors: "Tres leches", servings: 18)
        ]
    }
}
