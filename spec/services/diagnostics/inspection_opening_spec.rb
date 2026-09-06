require "rails_helper"

RSpec.describe Diagnostics::InspectionOpening do
  let(:workshop) { create(:organization) }
  let(:technician) { create(:membership, organization: workshop, role: "technician").user }
  let(:vehicle) { create(:vehicle) }

  def open(**attributes)
    described_class.new(
      vehicle: vehicle, technician: technician, organization: workshop,
      attributes: { usage_value: 50_000 }.merge(attributes)
    ).call
  end

  it "abre la inspeccion con la plantilla vigente" do
    template = create(:inspection_template, vehicle_type: "car")

    result = open

    expect(result).to be_success
    expect(result.inspection.template).to eq(template)
  end

  # Sin checklist para esa clase de vehiculo no hay visita que hacer.
  it "avisa si no hay plantilla publicada para esa clase de vehiculo" do
    result = open

    expect(result.error).to eq(:no_template)
  end

  it "avisa si los datos de la inspeccion no sirven" do
    create(:inspection_template, vehicle_type: "car")

    result = open(usage_value: nil)

    expect(result.error).to eq(:invalid)
  end

  # Se le cerro la app a mitad de la visita, no cambio de trabajo.
  it "retoma la que ya tenia abierta" do
    create(:inspection_template, vehicle_type: "car")
    primera = open.inspection

    expect(open.inspection).to eq(primera)
  end

  it "no retoma la de otro tecnico" do
    create(:inspection_template, vehicle_type: "car")
    otro = create(:membership, organization: workshop, role: "technician").user
    described_class.new(vehicle: vehicle, technician: otro, organization: workshop,
      attributes: { usage_value: 10 }).call

    expect { open }.to change(Diagnostics::Inspection, :count).by(1)
  end
end
