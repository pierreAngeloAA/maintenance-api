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
      # De donde salio el dato: no todos los registros valen lo mismo.
      recordedBy: {
        source: record.source,
        userName: record.recorded_by_user&.name,
        organizationName: record.recorded_by_organization&.name
      },
      createdAt: record.created_at
    }
  end
end
