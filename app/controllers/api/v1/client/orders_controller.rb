module Api
  module V1
    module Client
      # El cliente compra repuestos para su vehiculo.
      class OrdersController < ApplicationController
        include OrderPlacement

        # El alcance ya lo pone la consulta: las ordenes de este usuario.
        skip_authorization

        def index
          orders = Orders::Order
            .where(buyer: current_user)
            .includes(:items, :seller_organization)
            .recent_first

          render json: orders.map { |order| OrderSerializer.call(order) }
        end

        def show
          order = Orders::Order.where(buyer: current_user).find(params[:id])

          render json: OrderSerializer.call(order)
        end

        def create
          place_order(current_user)
        end
      end
    end
  end
end
