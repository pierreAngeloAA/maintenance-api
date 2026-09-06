module ServiceRequestSerializer
  module_function

  def call(request)
    {
      id: request.id,
      vehicleId: request.vehicle_id,
      kind: request.kind,
      status: request.status,
      scheduledFor: request.scheduled_for,
      address: request.address,
      notes: request.notes,
      createdAt: request.created_at
    }
  end
end
