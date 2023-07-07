import SwiftUI
import StoreKit

struct IAPStoreView: View {
    let iapManager: IAPManager
    @Binding var isPresenting: Bool
    @State private var quantity: Int = 1
    @State private var products: [String: Product] = [:]
    typealias ProductId = IAPManager.ProductId

    private func productDisplayPrice(for product: Product?) -> String {
        guard let product else { return "" }
        let price = product.price
        let adjustedPrice = price * Decimal(quantity)
        let formatStyle = product.priceFormatStyle
        return formatStyle.format(adjustedPrice)
    }

    var body: some View {
        VStack (spacing: 14) {
            Text("Support Hourglass").fontWeight(.medium)

            Form {
                Picker("Quantity:", selection: $quantity) {
                    Text("1x").tag(1)
                    Text("3x").tag(3)
                    Text("5x").tag(5)
                }

                HStack {
                    let tipProduct = products[ProductId.tip.rawValue]
                    let tipDislayPrice = productDisplayPrice(for: tipProduct)
                    Button("Tip \(tipDislayPrice)") {
                        Task {
                            guard let tipProduct else { return }
                            let purchaseResult = try await iapManager.purchase(product: tipProduct, quantity: quantity)

                            switch purchaseResult {
                            case .success(let verificationResult):
                                switch verificationResult {
                                case .verified(let transaction):
                                    await transaction.finish()
                                    isPresenting.toggle()
                                case .unverified(_, let verificationError):
                                    throw verificationError
                                }
                            default:
                                break
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.Hourglass.accent)
                    .disabled(tipProduct == nil)

                    Button("Close", role: .cancel) {
                        isPresenting.toggle()
                    }
                }
            }
            .pickerStyle(.segmented)
        }
        .task(priority: .background) {
            if let products = try? await iapManager.products() {
                self.products = products.reduce(into: [:]) { partialResult, product in
                    partialResult[product.id] = product
                }
            }
        }
        .font(.system(.body))
        .frame(width: 220)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
}

struct IAPStoreView_Previews: PreviewProvider {
    static var previews: some View {
        IAPStoreView(iapManager: IAPManager.shared,
                     isPresenting: .constant(true))
    }
}