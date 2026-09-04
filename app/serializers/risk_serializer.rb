module RiskSerializer
  module_function

  def call(risk)
    {
      partType: PartTypeSerializer.call(risk.part_type),
      usageSinceService: risk.usage_since_service,
      # De donde salio el uso acumulado: last_service, vehicle_total o model_year.
      basis: risk.basis,
      lifeUnit: risk.life_unit,
      failureProbability: risk.failure_probability,
      conditionalRisk: risk.conditional_risk,
      horizon: risk.horizon,
      # True mientras los parametros sean estimaciones y no datos de usuarios.
      estimate: risk.estimate,
      # Ajuste por clima y terreno de la ciudad del vehiculo. 1,0 es sin ajuste;
      # menos de 1,0 significa que en ese contexto la pieza dura menos.
      contextFactor: risk.context_factor
    }
  end
end
