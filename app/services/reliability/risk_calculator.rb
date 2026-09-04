module Reliability
  # El corazon del producto: la probabilidad de falla de una pieza no es un
  # numero fijo sino una curva que crece con el uso.
  #
  # Para cada pieza que aplica al vehiculo calcula:
  #
  #   t                     uso acumulado desde el ultimo cambio de esa pieza
  #   n = eta x factores    vida caracteristica ajustada por el contexto del vehiculo
  #   R(t) = exp(-(t/n)^b)  probabilidad de que siga sana
  #   F(t) = 1 - R(t)       probabilidad de que ya haya llegado al final de su vida
  #   P = 1 - R(t+dt)/R(t)  riesgo de falla en el proximo tramo, dado que llego sana hasta t
  #
  # El riesgo condicional es el numero util: no importa cuanto ha durado, sino
  # que tan probable es que falle en lo que viene.
  class RiskCalculator
    # Tramo por defecto para el riesgo condicional, segun la unidad de la pieza.
    DEFAULT_HORIZONS = { "km" => 1_000, "hours" => 50, "months" => 1 }.freeze

    Result = Data.define(
      :part_type,
      :usage_since_service,
      :basis,
      :life_unit,
      :failure_probability,
      :conditional_risk,
      :horizon,
      :estimate,
      :context_factor
    )

    def initialize(vehicle, horizon: nil)
      @vehicle = vehicle
      @horizon = horizon
    end

    def call
      part_types = vehicle.part_types.includes(:reliability_profiles).to_a

      part_types.filter_map { |part_type| result_for(part_type) }
        .sort_by { |result| -result.conditional_risk }
    end

    private

    attr_reader :vehicle, :horizon

    def result_for(part_type)
      profile = part_type.reliability_profiles.find { |p| p.vehicle_type == vehicle.vehicle_type }
      return if profile.nil?

      elapsed = elapsed_for(profile)
      span = horizon_for(profile)
      factor = context.life_factor_for(part_type.code)

      Result.new(
        part_type: part_type,
        usage_since_service: elapsed.value,
        basis: elapsed.basis,
        life_unit: profile.life_unit,
        failure_probability: profile.failure_probability_at(elapsed.value, life_factor: factor),
        conditional_risk: conditional_risk(profile, elapsed.value, span, factor),
        horizon: span,
        estimate: profile.estimate?,
        context_factor: factor
      )
    end

    # El contexto depende del vehiculo, no de la pieza: se resuelve una vez.
    def context
      @context ||= ContextFactors.for(vehicle)
    end

    Elapsed = Data.define(:value, :basis)

    def elapsed_for(profile)
      record = last_record_for(profile.part_type)

      if profile.life_unit == "months"
        months_elapsed(record)
      else
        usage_elapsed(record)
      end
    end

    def usage_elapsed(record)
      return Elapsed.new(value: vehicle.usage_value.to_f, basis: :vehicle_total) if record.nil?

      value = vehicle.usage_value.to_f - record.usage_at_service.to_f

      Elapsed.new(value: [ value, 0.0 ].max, basis: :last_service)
    end

    # Sin historial no sabemos cuando se cambio la pieza, asi que contamos desde
    # el ano del modelo. El resultado dice `:model_year` para que la interfaz
    # pueda aclararlo en vez de aparentar una precision que no tiene.
    def months_elapsed(record)
      if record
        Elapsed.new(value: months_between(record.performed_on), basis: :last_service)
      else
        Elapsed.new(value: months_between(Date.new(vehicle.model_year, 1, 1)), basis: :model_year)
      end
    end

    def months_between(date)
      months = (Date.current.year * 12 + Date.current.month) - (date.year * 12 + date.month)

      [ months, 0 ].max.to_f
    end

    def conditional_risk(profile, elapsed, span, factor)
      survived = profile.reliability_at(elapsed, life_factor: factor)
      # Pieza tan gastada que la confiabilidad se hace cero: el riesgo es total,
      # y ademas no se puede dividir por cero.
      return 1.0 if survived <= 0

      risk = 1.0 - (profile.reliability_at(elapsed + span, life_factor: factor) / survived)

      risk.clamp(0.0, 1.0)
    end

    def horizon_for(profile)
      horizon || DEFAULT_HORIZONS.fetch(profile.life_unit)
    end

    def last_record_for(part_type)
      vehicle.maintenance_records
        .where(part_type: part_type)
        .order(usage_at_service: :desc, performed_on: :desc)
        .first
    end
  end
end
