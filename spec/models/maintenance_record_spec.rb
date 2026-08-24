require "rails_helper"

RSpec.describe MaintenanceRecord, type: :model do
  let(:vehicle) { create(:vehicle, :motorcycle, usage_value: 12_000) }
  let(:drive_chain) { create(:part_type, :drive_chain) }

  describe "atributos basicos" do
    it "es valido con los atributos de la factory" do
      expect(build(:maintenance_record)).to be_valid
    end

    it "pertenece a un vehiculo y a un tipo de pieza" do
      record = build(:maintenance_record, vehicle: nil, part_type: nil)

      expect(record).not_to be_valid
      expect(record.errors[:vehicle]).to be_present
      expect(record.errors[:part_type]).to be_present
    end

    it "exige la fecha del mantenimiento" do
      expect(build(:maintenance_record, performed_on: nil)).not_to be_valid
    end

    it "rechaza un mantenimiento con fecha futura" do
      expect(build(:maintenance_record, performed_on: Date.current + 1)).not_to be_valid
    end

    it "arma los mensajes de error sin reventar: el API los serializa en el 422" do
      record = build(:maintenance_record, performed_on: Date.current + 1)
      record.validate

      expect { record.errors.full_messages }.not_to raise_error
      expect(record.errors.full_messages).to be_present
    end

    it "acepta un mantenimiento hecho hoy" do
      expect(build(:maintenance_record, performed_on: Date.current)).to be_valid
    end

    it "guarda la marca del repuesto, que despues entra al modelo de riesgo" do
      record = create(:maintenance_record, part_brand: "DID")

      expect(record.reload.part_brand).to eq("DID")
    end

    it "no exige la marca del repuesto: el usuario no siempre la sabe" do
      expect(build(:maintenance_record, part_brand: nil)).to be_valid
    end
  end

  describe "uso al momento del mantenimiento" do
    it "exige el uso" do
      expect(build(:maintenance_record, usage_at_service: nil)).not_to be_valid
    end

    it "rechaza un uso negativo" do
      expect(build(:maintenance_record, usage_at_service: -1)).not_to be_valid
    end

    it "rechaza un uso mayor al uso actual del vehiculo" do
      record = build(:maintenance_record, vehicle: vehicle, part_type: drive_chain, usage_at_service: 12_001)

      expect(record).not_to be_valid
      expect(record.errors[:usage_at_service]).to be_present
    end

    it "acepta un mantenimiento hecho justo con el uso actual" do
      record = build(:maintenance_record, vehicle: vehicle, part_type: drive_chain, usage_at_service: 12_000)

      expect(record).to be_valid
    end
  end

  describe "coherencia entre la pieza y el vehiculo" do
    it "rechaza una pieza que no aplica a esa clase de vehiculo" do
      timing_belt = create(:part_type, :timing_belt)
      record = build(:maintenance_record, vehicle: vehicle, part_type: timing_belt)

      expect(record).not_to be_valid
      expect(record.errors[:part_type]).to be_present
    end

    it "acepta una pieza que si aplica" do
      record = build(:maintenance_record, vehicle: vehicle, part_type: drive_chain, usage_at_service: 11_500)

      expect(record).to be_valid
    end
  end

  describe ".latest_per_part_type" do
    it "devuelve solo el mantenimiento mas reciente de cada pieza" do
      oil = create(:part_type, code: "engine_oil", applicable_vehicle_types: %w[car motorcycle])
      create(:maintenance_record, vehicle: vehicle, part_type: drive_chain, usage_at_service: 4_000)
      last_chain = create(:maintenance_record, vehicle: vehicle, part_type: drive_chain, usage_at_service: 11_500)
      last_oil = create(:maintenance_record, vehicle: vehicle, part_type: oil, usage_at_service: 9_000)

      result = vehicle.maintenance_records.latest_per_part_type

      expect(result).to contain_exactly(last_chain, last_oil)
    end

    it "devuelve vacio para un vehiculo sin historial" do
      expect(vehicle.maintenance_records.latest_per_part_type).to be_empty
    end
  end

  describe "asociacion con el vehiculo" do
    it "borra el historial cuando se borra el vehiculo" do
      create(:maintenance_record, vehicle: vehicle, part_type: drive_chain, usage_at_service: 1_000)

      expect { vehicle.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
