require "rails_helper"

RSpec.describe ReliabilityProfile, type: :model do
  describe "atributos basicos" do
    it "es valido con los atributos de la factory" do
      expect(build(:reliability_profile)).to be_valid
    end

    it "pertenece a un tipo de pieza" do
      expect(build(:reliability_profile, part_type: nil)).not_to be_valid
    end

    it "exige la clase de vehiculo" do
      expect(build(:reliability_profile, vehicle_type: nil)).not_to be_valid
    end

    it "rechaza una clase de vehiculo que no soportamos" do
      expect(build(:reliability_profile, vehicle_type: "submarine")).not_to be_valid
    end

    it "no permite dos perfiles para la misma pieza y clase de vehiculo" do
      profile = create(:reliability_profile)

      duplicate = build(:reliability_profile, part_type: profile.part_type, vehicle_type: profile.vehicle_type)

      expect(duplicate).not_to be_valid
    end

    it "permite el mismo tipo de pieza para clases de vehiculo distintas" do
      profile = create(:reliability_profile, vehicle_type: "car")

      expect(build(:reliability_profile, part_type: profile.part_type, vehicle_type: "motorcycle")).to be_valid
    end
  end

  describe "parametros de Weibull" do
    it "rechaza una forma menor o igual a cero: la curva no existiria" do
      expect(build(:reliability_profile, weibull_shape: 0)).not_to be_valid
      expect(build(:reliability_profile, weibull_shape: -1)).not_to be_valid
    end

    it "rechaza una vida caracteristica menor o igual a cero" do
      expect(build(:reliability_profile, characteristic_life: 0)).not_to be_valid
    end

    it "exige una unidad de vida conocida" do
      expect(build(:reliability_profile, life_unit: "parsecs")).not_to be_valid
      expect(build(:reliability_profile, life_unit: "months")).to be_valid
    end
  end

  describe "origen del dato" do
    it "por defecto es una estimacion de ingenieria" do
      expect(described_class.new.source).to eq("engineering_estimate")
    end

    it "rechaza un origen desconocido" do
      expect(build(:reliability_profile, source: "adivinanza")).not_to be_valid
    end

    it "distingue los perfiles calculados con datos de usuarios" do
      profile = build(:reliability_profile, source: "user_data")

      expect(profile).to be_valid
      expect(profile).not_to be_estimate
    end

    it "marca como estimacion los que salen de intervalos de fabricante" do
      expect(build(:reliability_profile, source: "engineering_estimate")).to be_estimate
    end
  end

  describe ".for" do
    it "encuentra el perfil de una pieza para una clase de vehiculo" do
      profile = create(:reliability_profile, vehicle_type: "motorcycle")

      expect(described_class.for(profile.part_type, "motorcycle")).to eq(profile)
    end

    it "devuelve nil si esa combinacion no esta parametrizada todavia" do
      profile = create(:reliability_profile, vehicle_type: "motorcycle")

      expect(described_class.for(profile.part_type, "car")).to be_nil
    end
  end

  describe "#reliability_at y #failure_probability_at" do
    subject(:profile) { build(:reliability_profile, weibull_shape: 2, characteristic_life: 20_000) }

    it "arranca en confiabilidad total con uso cero" do
      expect(profile.reliability_at(0)).to eq(1.0)
    end

    it "en la vida caracteristica ya fallo el 63,2%" do
      expect(profile.failure_probability_at(20_000)).to be_within(0.001).of(0.632)
    end

    it "la confiabilidad siempre baja al aumentar el uso" do
      expect(profile.reliability_at(30_000)).to be < profile.reliability_at(10_000)
    end

    it "nunca devuelve una probabilidad fuera de [0,1]" do
      [ 0, 1, 20_000, 500_000 ].each do |usage|
        expect(profile.failure_probability_at(usage)).to be_between(0, 1)
      end
    end

    it "trata un uso negativo como cero en vez de reventar" do
      expect(profile.failure_probability_at(-5)).to eq(0.0)
    end
  end
end
