module Services
  # Un tecnico toma un servicio.
  #
  # Es la operacion que ata todo el producto: crea la orden de trabajo y, con
  # ella, **el permiso del taller sobre el vehiculo**. Hasta ahora ese permiso se
  # otorgaba a mano; el camino normal pasa a ser este, porque nadie deberia tener
  # que entender el modelo de permisos para usar la app.
  #
  # Todo en una transaccion, y con un indice unico sobre `request_id` en las
  # ordenes: si dos tecnicos aceptan a la vez, uno gana y el otro recibe un
  # error, sin depender de que el codigo revise primero.
  class OfferAcceptance
    Result = Data.define(:order, :error) do
      def success? = error.nil?
    end

    def initialize(offer, technician)
      @offer = offer
      @technician = technician
    end

    def call
      return failure(:offer_not_open) unless offer.open?
      return failure(:request_not_open) unless offer.request.open?

      order = nil

      ActiveRecord::Base.transaction do
        order = create_order
        grant_vehicle_access(order)
        offer.update!(status: "accepted", technician_user: technician)
        offer.request.update!(status: "assigned")
        reject_other_offers
      end

      Result.new(order: order, error: nil)
    rescue ActiveRecord::RecordNotUnique
      # Otro tecnico gano la carrera.
      failure(:already_taken)
    end

    private

    attr_reader :offer, :technician

    def create_order
      Order.create!(
        request: offer.request,
        organization: offer.organization,
        technician_user: technician
      )
    end

    # El permiso vive lo que viva el servicio, y no un minuto mas.
    def grant_vehicle_access(order)
      Garage::VehicleAccessGrant.create!(
        vehicle: offer.request.vehicle,
        organization: offer.organization,
        granted_by: offer.request.requested_by_user,
        service_order: order,
        access_level: "write",
        granted_at: Time.current
      )
    end

    def reject_other_offers
      offer.request.offers.where.not(id: offer.id).update_all(status: "rejected")
    end

    def failure(error)
      Result.new(order: nil, error: error)
    end
  end
end
