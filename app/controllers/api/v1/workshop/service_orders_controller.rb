module Api
  module V1
    module Workshop
      # Los trabajos que el taller ya tomo.
      class ServiceOrdersController < BaseController
        skip_authorization only: :index

        def index
          orders = Services::Order
            .where(organization: Current.organization)
            .includes(:request)
            .order(created_at: :desc)

          render json: orders.map { |order| ServiceOrderSerializer.call(order) }
        end

        def update
          order = Services::Order.where(organization: Current.organization).find(params[:id])
          authorize order.technician_user_id == current_user.id
          return if performed?

          result = Services::OrderTransition.new(order, params.require(:status)).call

          if result.success?
            render json: ServiceOrderSerializer.call(result.order)
          else
            render json: { error: result.error }, status: :unprocessable_content
          end
        end
      end
    end
  end
end
