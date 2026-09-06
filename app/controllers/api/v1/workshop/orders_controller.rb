module Api
  module V1
    module Workshop
      # El taller compra repuestos para sus trabajos. La orden queda a nombre
      # del taller, no de la persona que la hizo.
      class OrdersController < BaseController
        include OrderPlacement

        skip_authorization

        def index
          orders = Orders::Order
            .where(buyer: Current.organization)
            .includes(:items, :seller_organization)
            .recent_first

          render json: orders.map { |order| OrderSerializer.call(order) }
        end

        def create
          place_order(Current.organization)
        end
      end
    end
  end
end
