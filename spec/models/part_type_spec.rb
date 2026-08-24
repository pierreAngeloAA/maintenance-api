require "rails_helper"

RSpec.describe PartType, type: :model do
  describe "atributos basicos" do
    it "es valido con los atributos de la factory" do
      expect(build(:part_type)).to be_valid
    end

    it "exige codigo, nombre y categoria" do
      part_type = build(:part_type, code: nil, name: nil, category: nil)

      expect(part_type).not_to be_valid
      expect(part_type.errors[:code]).to be_present
      expect(part_type.errors[:name]).to be_present
      expect(part_type.errors[:category]).to be_present
    end

    it "rechaza una categoria desconocida" do
      part_type = build(:part_type)
      part_type.category = "teletransportacion"

      expect(part_type).not_to be_valid
    end

    it "no permite dos piezas con el mismo codigo" do
      create(:part_type, code: "engine_oil")

      expect(build(:part_type, code: "engine_oil")).not_to be_valid
    end

    it "normaliza el codigo a minusculas" do
      part_type = create(:part_type, code: "Engine_Oil")

      expect(part_type.code).to eq("engine_oil")
    end
  end

  describe "clases de vehiculo aplicables" do
    it "exige al menos una clase de vehiculo" do
      part_type = build(:part_type, applicable_vehicle_types: [])

      expect(part_type).not_to be_valid
      expect(part_type.errors[:applicable_vehicle_types]).to be_present
    end

    it "rechaza una clase de vehiculo que no soportamos" do
      part_type = build(:part_type, applicable_vehicle_types: %w[car submarine])

      expect(part_type).not_to be_valid
    end

    it "acepta una pieza que aplica a varias clases de vehiculo" do
      expect(build(:part_type, applicable_vehicle_types: %w[car motorcycle])).to be_valid
    end
  end

  describe ".for_vehicle_type" do
    it "devuelve solo las piezas de esa clase de vehiculo" do
      chain = create(:part_type, :drive_chain)
      timing_belt = create(:part_type, :timing_belt)
      oil = create(:part_type, code: "engine_oil", applicable_vehicle_types: %w[car motorcycle])

      result = described_class.for_vehicle_type("motorcycle")

      expect(result).to include(chain, oil)
      expect(result).not_to include(timing_belt)
    end

    it "devuelve vacio para una clase de vehiculo sin piezas cargadas" do
      create(:part_type, :timing_belt)

      expect(described_class.for_vehicle_type("motorcycle")).to be_empty
    end
  end
end
