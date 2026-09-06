module ServiceOfferSerializer
  module_function

  def call(offer)
    request = offer.request

    {
      id: offer.id,
      status: offer.status,
      priceCents: offer.price_cents,
      expiresAt: offer.expires_at,
      request: {
        id: request.id,
        kind: request.kind,
        scheduledFor: request.scheduled_for,
        address: request.address,
        notes: request.notes
      },
      # Lo minimo para decidir si tomarlo: no se expone el vehiculo completo
      # hasta que el taller tenga permiso sobre el.
      vehicle: {
        vehicleType: request.vehicle.vehicle_type,
        make: request.vehicle.make,
        model: request.vehicle.model,
        modelYear: request.vehicle.model_year
      }
    }
  end
end
