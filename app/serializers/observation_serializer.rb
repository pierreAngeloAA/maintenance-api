module ObservationSerializer
  module_function

  def call(observation)
    {
      id: observation.id,
      itemId: observation.item_id,
      itemCode: observation.item.code,
      partTypeId: observation.part_type_id,
      value: observation.value,
      severity: observation.severity,
      notes: observation.notes
    }
  end
end
