# Comprar repuestos: lo hace igual un cliente para su carro que un taller para
# un trabajo. Lo unico que cambia es quien es el comprador.
module OrderPlacement
  extend ActiveSupport::Concern

  private

  def place_order(buyer)
    result = Orders::Placement.new(buyer: buyer, **order_params).call

    if result.success?
      render json: OrderSerializer.call(result.order), status: :created
    else
      render json: { error: result.error }, status: :unprocessable_content
    end
  end

  def order_params
    permitted = underscored_params.require(:order).permit(
      :address, :latitude, :longitude, items: [ :product_id, :quantity ]
    )

    {
      lines: (permitted[:items] || []).map { |i| i.to_h.symbolize_keys },
      address: permitted[:address],
      latitude: permitted[:latitude],
      longitude: permitted[:longitude]
    }
  end
end
