require "rails_helper"

RSpec.describe Reliability::ContextFactors do
  def context_for(city)
    described_class.for(build(:vehicle, city: city))
  end

  describe ".for" do
    it "reconoce el terreno y el clima de una ciudad del catalogo" do
      context = context_for("Bogota")

      expect(context.terrain).to eq("mountainous")
      expect(context.climate).to eq("cold_dry")
    end

    it "normaliza tildes, mayusculas y espacios sobrantes" do
      expect(context_for("  BOGOTÁ ").terrain).to eq(context_for("bogota").terrain)
      expect(context_for("Medellín").climate).to eq(context_for("medellin").climate)
    end

    it "no conoce el contexto de un vehiculo sin ciudad" do
      expect(context_for(nil)).not_to be_known
    end

    it "no conoce el contexto de una ciudad que no esta en el catalogo" do
      expect(context_for("Reikiavik")).not_to be_known
    end
  end

  describe "#life_factor_for" do
    it "castiga los frenos en una ciudad montanosa" do
      expect(context_for("Bogota").life_factor_for("brake_pads")).to be < 1.0
    end

    it "no castiga los frenos en una ciudad plana" do
      expect(context_for("Barranquilla").life_factor_for("brake_pads")).to eq(1.0)
    end

    it "castiga la bateria en una ciudad calurosa y humeda" do
      expect(context_for("Barranquilla").life_factor_for("battery")).to be < 1.0
    end

    it "castiga menos la bateria en una ciudad fria" do
      caliente = context_for("Barranquilla").life_factor_for("battery")
      fria = context_for("Bogota").life_factor_for("battery")

      expect(fria).to be > caliente
    end

    it "multiplica el factor de terreno por el de clima cuando los dos aplican" do
      montana_caliente = context_for("Bucaramanga")
      terrain = described_class.factors.dig("terrain", "mountainous", "tires")
      climate = described_class.factors.dig("climate", "hot_humid", "tires")

      expect(montana_caliente.life_factor_for("tires")).to be_within(1e-9).of(terrain * climate)
    end

    it "devuelve 1,0 para una pieza que el contexto no afecta" do
      expect(context_for("Bogota").life_factor_for("oil_filter")).to eq(1.0)
    end

    # El requisito duro del issue: un factor ausente nunca rompe el calculo.
    it "devuelve 1,0 cuando no hay contexto conocido" do
      expect(context_for(nil).life_factor_for("brake_pads")).to eq(1.0)
      expect(context_for("Reikiavik").life_factor_for("brake_pads")).to eq(1.0)
    end

    it "devuelve 1,0 para una pieza que ni siquiera existe en el catalogo" do
      expect(context_for("Bogota").life_factor_for("reactor_de_fusion")).to eq(1.0)
    end

    it "nunca devuelve un factor que anule la vida de la pieza" do
      described_class.cities.each_key do |city|
        PartTypeCatalog.entries.each do |part|
          expect(context_for(city).life_factor_for(part["code"])).to be > 0
        end
      end
    end
  end

  describe "coherencia del catalogo de datos" do
    it "toda ciudad declara un terreno y un clima definidos en los factores" do
      terrains = described_class.factors.fetch("terrain").keys
      climates = described_class.factors.fetch("climate").keys

      described_class.cities.each do |city, profile|
        expect(terrains).to include(profile["terrain"]), "#{city}: terreno #{profile['terrain']}"
        expect(climates).to include(profile["climate"]), "#{city}: clima #{profile['climate']}"
      end
    end

    it "solo castiga piezas que existen en el catalogo" do
      part_codes = PartTypeCatalog.entries.map { |entry| entry["code"] }

      described_class.factors.each_value do |profiles|
        profiles.each do |profile, parts|
          expect(part_codes).to include(*parts.keys) if parts.any?
        end
      end
    end

    it "todos los factores son positivos y acortan la vida, nunca la alargan" do
      described_class.factors.each_value do |profiles|
        profiles.each_value do |parts|
          parts.each_value do |factor|
            expect(factor).to be > 0
            expect(factor).to be <= 1.0
          end
        end
      end
    end

    it "las claves de ciudad ya vienen normalizadas" do
      described_class.cities.each_key do |city|
        expect(city).to eq(described_class.normalize(city))
      end
    end

    it "castiga en montana justo lo que dice el issue: frenos, clutch y llantas" do
      mountainous = described_class.factors.dig("terrain", "mountainous")

      expect(mountainous.keys).to include("brake_pads", "clutch_cable", "tires")
    end

    # Un auto y una moto sufren la montana igual. Si una clase queda sin castigo
    # en una categoria que la otra si tiene, es un olvido, no una decision.
    it "castiga frenos y suspension en las dos clases de vehiculo, no solo en el auto" do
      bogota = context_for("Bogota")

      PartTypeCatalog.entries
        .select { |part| %w[brakes suspension].include?(part["category"]) }
        .each do |part|
          expect(bogota.life_factor_for(part["code"])).to be < 1.0,
            "#{part['code']} (#{part['applicable_vehicle_types'].join(', ')}) no recibe castigo en montana"
        end
    end
  end
end
