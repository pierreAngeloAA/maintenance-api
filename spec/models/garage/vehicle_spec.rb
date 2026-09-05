require "rails_helper"

RSpec.describe Garage::Vehicle, type: :model do
  describe "atributos basicos" do
    it "es valido con los atributos de la factory" do
      expect(build(:vehicle)).to be_valid
    end

    it "exige el tipo de vehiculo" do
      vehicle = build(:vehicle, vehicle_type: nil)

      expect(vehicle).not_to be_valid
      expect(vehicle.errors[:vehicle_type]).to be_present
    end

    it "rechaza un tipo de vehiculo que todavia no soportamos" do
      vehicle = build(:vehicle)
      vehicle.vehicle_type = "boat"

      expect(vehicle).not_to be_valid
      expect(vehicle.errors[:vehicle_type]).to be_present
    end

    it "exige marca y modelo" do
      vehicle = build(:vehicle, make: nil, model: nil)

      expect(vehicle).not_to be_valid
      expect(vehicle.errors[:make]).to be_present
      expect(vehicle.errors[:model]).to be_present
    end

    it "rechaza un ano anterior a 1900" do
      expect(build(:vehicle, model_year: 1899)).not_to be_valid
    end

    it "rechaza un ano muy adelantado" do
      expect(build(:vehicle, model_year: Date.current.year + 3)).not_to be_valid
    end

    it "acepta el modelo del ano entrante" do
      expect(build(:vehicle, model_year: Date.current.year + 1)).to be_valid
    end
  end

  describe "VIN" do
    it "es opcional: una moto colombiana se registra sin VIN" do
      expect(build(:vehicle, :motorcycle, vin: nil)).to be_valid
    end

    it "acepta un VIN valido de 17 caracteres" do
      expect(build(:vehicle, vin: "1HGBH41JXMN109186")).to be_valid
    end

    it "rechaza un VIN que no tiene 17 caracteres" do
      expect(build(:vehicle, vin: "1HGBH41JXMN1091")).not_to be_valid
    end

    it "rechaza un VIN con I, O o Q (excluidas por el estandar ISO 3779)" do
      %w[1HGBH41JXMN10918I 1HGBH41JXMN10918O 1HGBH41JXMN10918Q].each do |invalid_vin|
        expect(build(:vehicle, vin: invalid_vin)).not_to be_valid
      end
    end

    it "normaliza el VIN a mayusculas" do
      vehicle = create(:vehicle, vin: "1hgbh41jxmn109186")

      expect(vehicle.vin).to eq("1HGBH41JXMN109186")
    end

    it "no permite dos vehiculos con el mismo VIN" do
      create(:vehicle, vin: "1HGBH41JXMN109186")

      expect(build(:vehicle, vin: "1HGBH41JXMN109186")).not_to be_valid
    end

    it "permite varios vehiculos sin VIN" do
      create(:vehicle, :motorcycle, vin: nil)

      expect(build(:vehicle, :motorcycle, vin: nil)).to be_valid
    end
  end

  describe "placa" do
    it "es opcional" do
      expect(build(:vehicle, plate: nil)).to be_valid
    end

    it "la normaliza a mayusculas y sin espacios" do
      vehicle = create(:vehicle, plate: " abc123 ")

      expect(vehicle.plate).to eq("ABC123")
    end
  end

  describe "uso acumulado" do
    it "rechaza un uso negativo" do
      expect(build(:vehicle, usage_value: -1)).not_to be_valid
    end

    it "acepta un vehiculo recien comprado con uso en cero" do
      expect(build(:vehicle, usage_value: 0)).to be_valid
    end

    it "exige que los vehiculos terrestres se midan en kilometros" do
      vehicle = build(:vehicle, usage_unit: "hours")

      expect(vehicle).not_to be_valid
      expect(vehicle.errors[:usage_unit]).to be_present
    end

    it "rechaza una unidad de uso desconocida" do
      vehicle = build(:vehicle)
      vehicle.usage_unit = "leagues"

      expect(vehicle).not_to be_valid
    end
  end

  describe "specs" do
    it "arranca como un hash vacio" do
      expect(create(:vehicle).specs).to eq({})
    end

    it "guarda atributos especificos de la clase de vehiculo" do
      vehicle = create(:vehicle, :motorcycle, specs: { "displacement_cc" => 150 })

      expect(vehicle.reload.specs["displacement_cc"]).to eq(150)
    end
  end
end
