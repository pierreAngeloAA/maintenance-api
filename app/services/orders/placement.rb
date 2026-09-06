module Orders
  # Crear una orden a partir de un carrito.
  #
  # Todo en una transaccion: congelar precios, descontar stock y crear la orden
  # tienen que pasar juntos o no pasar. Si dos personas compran la ultima unidad
  # a la vez, una gana y la otra recibe un error.
  class Placement
    Result = Data.define(:order, :error) do
      def success? = error.nil?
    end

    # Una orden es a UN almacen: mezclar vendedores en un solo pedido complicaria
    # el despacho y el pago sin darle nada al usuario.
    def initialize(buyer:, lines:, address: nil, latitude: nil, longitude: nil)
      @buyer = buyer
      @lines = lines
      @address = address
      @latitude = latitude
      @longitude = longitude
    end

    def call
      return failure(:empty_cart) if lines.blank?

      products = load_products
      return failure(:product_not_available) if products.length != lines.length
      return failure(:multiple_sellers) if products.map(&:organization_id).uniq.length > 1

      place(products)
    rescue ActiveRecord::RecordInvalid
      failure(:invalid)
    end

    private

    attr_reader :buyer, :lines, :address, :latitude, :longitude

    def load_products
      Catalog::Product.available.where(id: lines.map { |l| l[:product_id] }).to_a
    end

    def place(products)
      order = nil

      Order.transaction do
        order = Order.create!(
          buyer: buyer, seller_organization_id: products.first.organization_id,
          status: "pending", placed_at: Time.current,
          address: address, latitude: latitude, longitude: longitude
        )

        products.each { |product| add_line(order, product) }

        order.update!(subtotal_cents: total_of(order), total_cents: total_of(order))
      end

      Result.new(order: order, error: nil)
    rescue ActiveRecord::RecordNotSaved
      failure(:out_of_stock)
    end

    def add_line(order, product)
      quantity = quantity_for(product)
      raise ActiveRecord::RecordNotSaved if quantity > product.stock_quantity

      order.items.create!(
        product: product,
        # Copiados, no referenciados: la orden guarda lo que se vendio.
        product_name: product.name, product_brand: product.brand,
        product_sku: product.sku, quantity: quantity,
        unit_price_cents: product.unit_price_cents
      )

      product.update!(stock_quantity: product.stock_quantity - quantity)
    end

    def quantity_for(product)
      lines.find { |l| l[:product_id].to_i == product.id }[:quantity].to_i
    end

    def total_of(order)
      order.items.sum(&:total_cents)
    end

    def failure(error)
      Result.new(order: nil, error: error)
    end
  end
end
