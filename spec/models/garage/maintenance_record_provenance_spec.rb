require "rails_helper"

# De donde salio cada registro. No es burocracia: un cambio de pastillas
# anotado por un taller verificado vale mas para el modelo de riesgo que uno que
# el dueno escribio de memoria seis meses despues. Si el dato no se guarda desde
# el principio, esa informacion no se recupera.
RSpec.describe Garage::MaintenanceRecord, "procedencia", type: :model do
  let(:vehicle) { create(:vehicle) }
  let(:part_type) { create(:part_type, applicable_vehicle_types: [ vehicle.vehicle_type ]) }

  after { Current.reset }

  def build_record
    build(:maintenance_record, vehicle: vehicle, part_type: part_type)
  end

  it "sin actor, un registro queda como del dueno" do
    record = build_record
    record.save!

    expect(record.source).to eq("owner")
  end

  it "el dueno que lo registra queda anotado" do
    Current.user = vehicle.user

    record = build_record
    record.save!

    expect(record).to have_attributes(source: "owner", recorded_by_user_id: vehicle.user.id)
    expect(record.recorded_by_organization_id).to be_nil
  end

  it "un taller queda anotado con su tecnico y su organizacion" do
    membership = create(:membership, role: "technician")
    Current.user = membership.user
    Current.membership = membership
    Current.organization = membership.organization

    record = build_record
    record.save!

    expect(record).to have_attributes(
      source: "workshop",
      recorded_by_user_id: membership.user.id,
      recorded_by_organization_id: membership.organization.id
    )
  end

  # Al crear no se puede: la procedencia se deriva de Current y el parametro no
  # esta permitido. La validacion cuida el caso de que alguien la toque despues.
  it "rechaza un origen que no existe" do
    record = build_record
    record.save!
    record.source = "adivinado"

    expect(record).not_to be_valid
  end

  # La procedencia se fija al crear y no se reescribe despues.
  it "no cambia la procedencia al actualizar" do
    Current.user = vehicle.user
    record = build_record
    record.save!

    membership = create(:membership, role: "technician")
    Current.organization = membership.organization
    record.update!(notes: "corregido")

    expect(record.reload.source).to eq("owner")
  end
end
