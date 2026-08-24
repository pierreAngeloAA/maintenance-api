require "rails_helper"

RSpec.describe PartTypeCatalog do
  describe ".entries" do
    it "trae piezas definidas en el catalogo" do
      expect(described_class.entries).to be_present
    end

    it "define todas las piezas con codigo, nombre, categoria y clases aplicables" do
      described_class.entries.each do |entry|
        expect(PartType.new(entry)).to be_valid, "pieza invalida en el catalogo: #{entry.inspect}"
      end
    end

    it "no repite codigos" do
      codes = described_class.entries.map { |entry| entry["code"] }

      expect(codes).to eq(codes.uniq)
    end

    it "cubre todas las clases de vehiculo soportadas" do
      covered = described_class.entries.flat_map { |entry| entry["applicable_vehicle_types"] }.uniq

      expect(covered).to match_array(Vehicle.vehicle_types.keys)
    end
  end

  describe ".load!" do
    it "carga el catalogo en la base de datos" do
      expect { described_class.load! }.to change(PartType, :count).from(0)
    end

    it "es idempotente: correrlo dos veces no duplica piezas" do
      described_class.load!

      expect { described_class.load! }.not_to change(PartType, :count)
    end

    it "actualiza el nombre de una pieza que cambio en el catalogo" do
      described_class.load!
      part_type = PartType.find_by!(code: "engine_oil")
      part_type.update!(name: "Nombre viejo")

      described_class.load!

      expect(part_type.reload.name).not_to eq("Nombre viejo")
    end
  end

  describe "contenido del catalogo" do
    before { described_class.load! }

    it "la moto lleva cadena y kit de arrastre" do
      codes = PartType.for_vehicle_type("motorcycle").pluck(:code)

      expect(codes).to include("drive_chain", "chain_sprocket_kit")
    end

    it "la moto no lleva correa de repartición" do
      codes = PartType.for_vehicle_type("motorcycle").pluck(:code)

      expect(codes).not_to include("timing_belt")
    end

    it "el auto lleva correa de repartición pero no cadena" do
      codes = PartType.for_vehicle_type("car").pluck(:code)

      expect(codes).to include("timing_belt")
      expect(codes).not_to include("drive_chain")
    end

    it "las piezas comunes aplican a las dos clases de vehiculo" do
      expect(PartType.find_by!(code: "engine_oil").applicable_vehicle_types)
        .to match_array(%w[car motorcycle])
    end
  end
end
