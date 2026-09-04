require "rails_helper"

RSpec.describe ReliabilityProfileCatalog do
  describe ".entries" do
    it "define perfiles" do
      expect(described_class.entries).to be_present
    end

    it "solo referencia piezas que existen en el catalogo" do
      part_codes = PartTypeCatalog.entries.map { |entry| entry["code"] }

      described_class.entries.each do |entry|
        expect(part_codes).to include(entry["part_code"])
      end
    end

    it "no parametriza una pieza para una clase de vehiculo que no la lleva" do
      applicable = PartTypeCatalog.entries.to_h { |e| [ e["code"], e["applicable_vehicle_types"] ] }

      described_class.entries.each do |entry|
        expect(applicable[entry["part_code"]]).to include(entry["vehicle_type"]),
          "#{entry['part_code']} no aplica a #{entry['vehicle_type']}"
      end
    end

    it "no repite la combinacion de pieza y clase de vehiculo" do
      keys = described_class.entries.map { |entry| [ entry["part_code"], entry["vehicle_type"] ] }

      expect(keys).to eq(keys.uniq)
    end

    it "cubre todas las combinaciones de pieza y clase de vehiculo del catalogo" do
      expected = PartTypeCatalog.entries.flat_map do |entry|
        entry["applicable_vehicle_types"].map { |vehicle_type| [ entry["code"], vehicle_type ] }
      end
      actual = described_class.entries.map { |entry| [ entry["part_code"], entry["vehicle_type"] ] }

      expect(actual).to match_array(expected)
    end
  end

  describe ".load!" do
    before { PartTypeCatalog.load! }

    it "carga los perfiles" do
      expect { described_class.load! }.to change(ReliabilityProfile, :count).from(0)
    end

    it "es idempotente" do
      described_class.load!

      expect { described_class.load! }.not_to change(ReliabilityProfile, :count)
    end

    it "todos los perfiles cargados son validos" do
      described_class.load!

      expect(ReliabilityProfile.all).to all(be_valid)
    end

    it "marca los perfiles como estimacion de ingenieria" do
      described_class.load!

      expect(ReliabilityProfile.all).to all(be_estimate)
    end

    it "no pisa un perfil ya calculado con datos de usuarios" do
      described_class.load!
      profile = ReliabilityProfile.first
      profile.update!(source: "user_data", characteristic_life: 12_345)

      described_class.load!

      expect(profile.reload.characteristic_life).to eq(12_345)
      expect(profile.source).to eq("user_data")
    end
  end

  describe "coherencia de los parametros" do
    before do
      PartTypeCatalog.load!
      described_class.load!
    end

    it "el aceite de moto se cambia mucho antes que el de auto" do
      oil = PartType.find_by!(code: "engine_oil")
      moto = ReliabilityProfile.for(oil, "motorcycle")
      car = ReliabilityProfile.for(oil, "car")

      expect(moto.characteristic_life).to be < car.characteristic_life
    end

    it "las piezas que se degradan con el tiempo y no con el uso se miden en meses" do
      %w[battery brake_fluid].each do |code|
        profiles = PartType.find_by!(code: code).reliability_profiles

        expect(profiles.map(&:life_unit).uniq).to eq([ "months" ])
      end
    end

    it "el bombillo falla de forma casi aleatoria y la correa por desgaste marcado" do
      bulb = ReliabilityProfile.for(PartType.find_by!(code: "headlight_bulb"), "car")
      belt = ReliabilityProfile.for(PartType.find_by!(code: "timing_belt"), "car")

      expect(bulb.weibull_shape).to be < 1.5
      expect(belt.weibull_shape).to be > 3
    end
  end
end
