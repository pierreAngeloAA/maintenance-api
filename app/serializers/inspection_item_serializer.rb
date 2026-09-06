module InspectionItemSerializer
  module_function

  def call(item)
    {
      id: item.id,
      code: item.code,
      label: item.label,
      phase: item.phase,
      valueType: item.value_type,
      unit: item.unit,
      minimum: item.minimum,
      maximum: item.maximum,
      position: item.position,
      partTypeId: item.part_type_id
    }
  end
end
