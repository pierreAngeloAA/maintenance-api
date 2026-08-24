module VehicleSerializer
  module_function

  def call(vehicle, include_part_types: false)
    payload = {
      id: vehicle.id,
      vehicleType: vehicle.vehicle_type,
      make: vehicle.make,
      model: vehicle.model,
      modelYear: vehicle.model_year,
      vin: vehicle.vin,
      plate: vehicle.plate,
      usageValue: vehicle.usage_value,
      usageUnit: vehicle.usage_unit,
      city: vehicle.city,
      specs: vehicle.specs,
      createdAt: vehicle.created_at,
      updatedAt: vehicle.updated_at
    }

    return payload unless include_part_types

    payload.merge(partTypes: vehicle.part_types.map { |part_type| PartTypeSerializer.call(part_type) })
  end
end
