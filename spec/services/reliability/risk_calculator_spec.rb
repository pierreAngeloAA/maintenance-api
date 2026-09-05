require "rails_helper"

RSpec.describe Reliability::RiskCalculator do
  subject(:calculator) { described_class.new(vehicle) }

  let(:vehicle) { create(:vehicle, :motorcycle, usage_value: 18_000, model_year: Date.current.year - 2) }
  let(:chain) { create(:part_type, :drive_chain) }
  let!(:chain_profile) do
    create(:reliability_profile,
      part_type: chain, vehicle_type: "motorcycle",
      weibull_shape: 2, characteristic_life: 20_000, life_unit: "km")
  end

  def result_for(part_type)
    calculator.call.find { |result| result.part_type == part_type }
  end

  describe "uso desde el ultimo cambio" do
    it "usa el uso acumulado desde el ultimo mantenimiento de esa pieza" do
      create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 6_000)

      expect(result_for(chain).usage_since_service).to eq(12_000)
    end

    it "toma el mantenimiento mas reciente cuando hay varios" do
      create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 4_000)
      create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 15_000)

      expect(result_for(chain).usage_since_service).to eq(3_000)
    end

    it "usa el uso total del vehiculo cuando la pieza nunca se ha cambiado" do
      result = result_for(chain)

      expect(result.usage_since_service).to eq(18_000)
      expect(result.basis).to eq(:vehicle_total)
    end

    it "marca de donde salio el dato cuando si hay historial" do
      create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 6_000)

      expect(result_for(chain).basis).to eq(:last_service)
    end
  end

  describe "probabilidad de falla" do
    it "crece con el uso acumulado" do
      create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 17_000)
      poco_uso = result_for(chain).failure_probability

      MaintenanceRecord.delete_all
      mucho_uso = described_class.new(vehicle.reload).call.find { |r| r.part_type == chain }.failure_probability

      expect(mucho_uso).to be > poco_uso
    end

    it "en la vida caracteristica da 63,2%" do
      # Sin ciudad para medir la curva pura: con contexto la vida se acorta y el
      # 63,2% cae antes, que es justo lo que prueba el ajuste por contexto.
      vehicle.update!(usage_value: 20_000, city: nil)

      expect(result_for(chain).failure_probability).to be_within(0.001).of(0.632)
    end

    it "nunca sale del rango [0,1]" do
      vehicle.update!(usage_value: 900_000)

      expect(result_for(chain).failure_probability).to be_between(0, 1)
    end
  end

  describe "riesgo condicional en el proximo tramo" do
    it "una cadena gastada arriesga mucho mas en los proximos 2.000 km que una nueva" do
      # Cadena con 18.000 km encima: R(18000)/R(20000) da ~17% de falla en el tramo.
      # Sin ciudad para aislar la curva del ajuste por contexto.
      vehicle.update!(city: nil)
      gastada = described_class.new(vehicle, horizon: 2_000).call.find { |r| r.part_type == chain }

      create(:maintenance_record, vehicle: vehicle, part_type: chain, usage_at_service: 18_000)
      nueva = described_class.new(vehicle.reload, horizon: 2_000).call.find { |r| r.part_type == chain }

      expect(gastada.conditional_risk).to be_within(0.005).of(0.173)
      expect(nueva.conditional_risk).to be_within(0.005).of(0.010)
      expect(gastada.conditional_risk).to be > nueva.conditional_risk * 10
    end

    it "no revienta cuando la pieza esta tan gastada que la confiabilidad se hace cero" do
      vehicle.update!(usage_value: 900_000)

      expect(result_for(chain).conditional_risk).to be_between(0, 1)
    end
  end

  describe "piezas que se degradan con el tiempo" do
    let(:battery) { create(:part_type, code: "battery", applicable_vehicle_types: %w[car motorcycle]) }
    let!(:battery_profile) do
      create(:reliability_profile,
        part_type: battery, vehicle_type: "motorcycle",
        weibull_shape: 2.5, characteristic_life: 24, life_unit: "months")
    end

    it "cuenta meses desde el ultimo cambio, no kilometros" do
      create(:maintenance_record, vehicle: vehicle, part_type: battery,
        performed_on: Date.current << 6, usage_at_service: 1_000)

      result = result_for(battery)

      expect(result.life_unit).to eq("months")
      expect(result.usage_since_service).to be_within(0.1).of(6)
    end

    it "sin historial cuenta desde el ano del modelo y lo deja claro" do
      result = result_for(battery)

      expect(result.basis).to eq(:model_year)
      expect(result.usage_since_service).to be > 12
    end
  end

  describe "resultado" do
    it "ordena las piezas de mayor a menor riesgo" do
      oil = create(:part_type, code: "engine_oil", applicable_vehicle_types: %w[motorcycle])
      create(:reliability_profile, part_type: oil, vehicle_type: "motorcycle",
        weibull_shape: 3.5, characteristic_life: 3_000, life_unit: "km")

      risks = calculator.call.map(&:conditional_risk)

      expect(risks).to eq(risks.sort.reverse)
    end

    it "dice si el parametro todavia es una estimacion de ingenieria" do
      expect(result_for(chain).estimate).to be(true)
    end

    it "ignora las piezas que no aplican a esa clase de vehiculo" do
      timing_belt = create(:part_type, :timing_belt)
      create(:reliability_profile, part_type: timing_belt, vehicle_type: "car",
        weibull_shape: 4, characteristic_life: 80_000, life_unit: "km")

      expect(result_for(timing_belt)).to be_nil
    end

    it "ignora las piezas que todavia no tienen parametros cargados" do
      sin_perfil = create(:part_type, code: "misterio", applicable_vehicle_types: %w[motorcycle])

      expect(result_for(sin_perfil)).to be_nil
    end
  end

  # El mismo repuesto no dura lo mismo en Bogota que en Barranquilla. Se modela
  # como vida acelerada: cambia eta, no la matematica del riesgo.
  describe "ajuste por contexto del vehiculo" do
    let(:brake_pads) { create(:part_type, code: "brake_pads", applicable_vehicle_types: %w[car motorcycle]) }
    let!(:brake_profile) do
      create(:reliability_profile,
        part_type: brake_pads, vehicle_type: "motorcycle",
        weibull_shape: 2.5, characteristic_life: 25_000, life_unit: "km")
    end

    def brakes_in(city)
      vehicle.update!(city: city)

      described_class.new(vehicle.reload).call.find { |result| result.part_type == brake_pads }
    end

    it "una moto en Bogota arriesga mas los frenos que la misma moto en Barranquilla" do
      montana = brakes_in("Bogota")
      plano = brakes_in("Barranquilla")

      expect(montana.conditional_risk).to be > plano.conditional_risk
    end

    it "expone el factor aplicado para que la interfaz pueda explicarlo" do
      expect(brakes_in("Bogota").context_factor).to be < 1.0
      expect(brakes_in("Barranquilla").context_factor).to eq(1.0)
    end

    it "un vehiculo sin ciudad da exactamente el mismo resultado que antes del ajuste" do
      sin_ciudad = brakes_in(nil)
      sin_factor = brake_profile.failure_probability_at(sin_ciudad.usage_since_service)

      expect(sin_ciudad.context_factor).to eq(1.0)
      expect(sin_ciudad.failure_probability).to be_within(1e-9).of(sin_factor)
    end

    it "una ciudad desconocida no rompe el calculo: se comporta como sin contexto" do
      expect(brakes_in("Reikiavik").context_factor).to eq(1.0)
      expect(brakes_in("Reikiavik").conditional_risk).to be_between(0, 1)
    end

    it "el contexto no saca la probabilidad del rango [0,1]" do
      vehicle.update!(usage_value: 900_000)

      expect(brakes_in("Bogota").failure_probability).to be_between(0, 1)
      expect(brakes_in("Bogota").conditional_risk).to be_between(0, 1)
    end
  end
end
