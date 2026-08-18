import SwiftUI

struct RootView: View {
    @State private var store = AppStore()
    @State private var selection: Int = 0
    @State private var calculatorSpec: CakeSpec?

    var body: some View {
        TabView(selection: $selection) {
            DashboardView(selection: $selection)
                .tabItem { Label("Inicio", systemImage: "house.fill") }
                .tag(0)

            OrdersView()
                .tabItem { Label("Pedidos", systemImage: "bag.fill") }
                .tag(1)

            CalculatorView()
                .tabItem { Label("Calcular", systemImage: "square.grid.2x2.fill") }
                .tag(2)

            ProductionView()
                .tabItem { Label("Producción", systemImage: "frying.pan.fill") }
                .tag(3)

            MoreView()
                .tabItem { Label("Más", systemImage: "ellipsis") }
                .tag(4)
        }
        .tint(Theme.accentDeep)
        .environment(store)
    }
}

#Preview {
    RootView()
}
