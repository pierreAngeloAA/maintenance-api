module MaintenanceRecordSerializer
  module_function

  def call(record)
    {
      id: record.id,
      vehicleId: record.vehicle_id,
      partType: PartTypeSerializer.call(record.part_type),
      performedOn: record.performed_on,
      usageAtService: record.usage_at_service,
      partBrand: record.part_brand,
      costCents: record.cost_cents,
      currency: record.currency,
      notes: record.notes,
      createdAt: record.created_at
    }
  end
end
