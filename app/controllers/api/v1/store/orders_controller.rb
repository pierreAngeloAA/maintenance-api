module Api
  module V1
    module Store
      # Las ventas del almacen.
      class OrdersController < BaseController
        skip_authorization only: :index

        def index
          orders = sales.includes(:items, :seller_organization).recent_first

          render json: orders.map { |order| OrderSerializer.call(order) }
        end

        # Mover la venta: pagada, despachada, entregada.
        def update
          order = sales.find(params[:id])
          authorize OrderPolicy.fulfill?(order)
          return if performed?

          next_status = params.require(:status).to_s

          unless order.can_transition_to?(next_status)
            return render json: { error: "invalid_transition" }, status: :unprocessable_content
          end

          order.transaction do
            order.update!(status: next_status)
            record_payment(order) if next_status == "paid"
          end

          render json: OrderSerializer.call(order)
        rescue ActiveRecord::RecordInvalid => e
          # Tipicamente una referencia de pasarela repetida: es un error del
          # que la manda, no una caida.
          render json: { errors: camelized_errors(e.record) }, status: :unprocessable_content
        end

        private

        # Con la opcion A el dinero va directo del cliente al almacen: la
        # plataforma nunca lo toca. Lo unico que guarda es la referencia de la
        # pasarela, para que comprador y vendedor puedan conciliar.
        def record_payment(order)
          payment = underscored_params[:payment]
          return if payment.blank?

          order.payments.create!(
            gateway: payment[:gateway], gateway_ref: payment[:gateway_ref],
            status: "approved", amount_cents: order.total_cents
          )
        end

        def sales
          Orders::Order.where(seller_organization: Current.organization)
        end
      end
    end
  end
end
