module Services
  # Mueve una orden de estado, y con ella el permiso sobre el vehiculo.
  #
  # Cerrar o cancelar el servicio **revoca el permiso**: el taller entra a la
  # historia del vehiculo mientras dura el trabajo, no para siempre.
  class OrderTransition
    Result = Data.define(:order, :error) do
      def success? = error.nil?
    end

    def initialize(order, next_status)
      @order = order
      @next_status = next_status.to_s
    end

    def call
      return failure(:invalid_transition) unless order.can_transition_to?(next_status)

      ActiveRecord::Base.transaction do
        order.update!(status: next_status, **timestamps)
        close_out if order.final?
      end

      Result.new(order: order, error: nil)
    end

    private

    attr_reader :order, :next_status

    def timestamps
      case next_status
      when "in_progress" then { started_at: order.started_at || Time.current }
      when "completed" then { completed_at: Time.current }
      else {}
      end
    end

    def close_out
      order.request.update!(status: next_status == "completed" ? "completed" : "canceled")
      Garage::VehicleAccessGrant.where(service_order: order).find_each(&:revoke!)
    end

    def failure(error)
      Result.new(order: nil, error: error)
    end
  end
end
