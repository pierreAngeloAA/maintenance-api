require "rails_helper"

RSpec.describe Runt::VehicleLookupJob do
  let(:vehicle) { create(:vehicle, plate: "ABC123", make: "Renault", model: "Logan") }

  def run_with(result)
    allow(Runt::PlacapiClient).to receive(:new).and_return(
      instance_double(Runt::PlacapiClient, call: result)
    )

    described_class.perform_now(vehicle.id)
    vehicle.reload
  end

  def result(**attributes)
    Runt::PlacapiClient::Result.new(**Runt::PlacapiClient::EMPTY_RESULT.to_h.merge(attributes))
  end

  it "guarda los vencimientos de SOAT y tecnomecanica" do
    run_with(result(make: "RENAULT", soat_expires_on: Date.new(2027, 3, 15),
                    technical_inspection_expires_on: Date.new(2027, 1, 20)))

    expect(vehicle).to have_attributes(
      soat_expires_on: Date.new(2027, 3, 15),
      technical_inspection_expires_on: Date.new(2027, 1, 20)
    )
  end

  it "deja constancia de cuando se consulto" do
    run_with(result(make: "RENAULT"))

    expect(vehicle.runt_checked_at).to be_present
  end

  # Enriquecimiento, no correccion: lo que el usuario escribio manda.
  it "no pisa los datos que el usuario ya escribio" do
    run_with(result(make: "OTRA MARCA", line: "OTRA LINEA"))

    expect(vehicle.make).to eq("Renault")
  end

  it "si no encuentra nada, el vehiculo queda igual" do
    run_with(Runt::PlacapiClient::EMPTY_RESULT)

    expect(vehicle.soat_expires_on).to be_nil
    expect(vehicle.runt_checked_at).to be_present
  end

  it "no revienta si el vehiculo ya no existe" do
    id = vehicle.id
    vehicle.destroy

    expect { described_class.perform_now(id) }.not_to raise_error
  end

  it "no consulta si el vehiculo no tiene placa" do
    sin_placa = create(:vehicle, plate: nil)
    expect(Runt::PlacapiClient).not_to receive(:new)

    described_class.perform_now(sin_placa.id)
  end
end
