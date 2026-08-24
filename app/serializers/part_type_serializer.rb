module PartTypeSerializer
  module_function

  def call(part_type)
    {
      id: part_type.id,
      code: part_type.code,
      name: part_type.name,
      category: part_type.category,
      applicableVehicleTypes: part_type.applicable_vehicle_types
    }
  end
end
