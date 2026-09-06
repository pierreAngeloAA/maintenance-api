module ServiceOrderSerializer
  module_function

  def call(order)
    {
      id: order.id,
      status: order.status,
      requestId: order.request_id,
      vehicleId: order.request.vehicle_id,
      technicianUserId: order.technician_user_id,
      startedAt: order.started_at,
      completedAt: order.completed_at,
      totalCents: order.total_cents,
      createdAt: order.created_at
    }
  end
end
