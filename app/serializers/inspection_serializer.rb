module InspectionSerializer
  module_function

  def call(inspection, include_items: false)
    payload = {
      id: inspection.id,
      vehicleId: inspection.vehicle_id,
      status: inspection.status,
      usageValue: inspection.usage_value,
      startedAt: inspection.started_at,
      performedAt: inspection.performed_at,
      durationSeconds: inspection.duration_seconds,
      summary: inspection.summary,
      photoCount: inspection.photos.count,
      observations: inspection.observations.map { |o| ObservationSerializer.call(o) }
    }

    return payload unless include_items

    # Los items van con la inspeccion y no aparte: la plantilla se versiona, asi
    # que una inspeccion vieja tiene que seguir mostrando los campos con los que
    # se hizo, no los de la version actual.
    payload.merge(items: inspection.template.items.map { |i| InspectionItemSerializer.call(i) })
  end
end
