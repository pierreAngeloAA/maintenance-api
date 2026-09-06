require "rails_helper"

RSpec.describe InspectionTemplateCatalog do
  before { PartTypeCatalog.load! }

  it "carga un checklist por clase de vehiculo" do
    described_class.load!

    expect(Diagnostics::InspectionTemplate.pluck(:vehicle_type)).to match_array(%w[car motorcycle])
  end

  it "carga los campos de cada checklist" do
    described_class.load!

    expect(Diagnostics::InspectionItem.count).to be_positive
  end

  it "cubre las tres fases de la visita" do
    described_class.load!

    expect(Diagnostics::InspectionItem.distinct.pluck(:phase))
      .to match_array(%w[engine_off engine_idle driving])
  end

  # La regla que hace valiosa la visita: milimetros, no adjetivos.
  it "el labrado y la presion se miden con unidad, no con una escala" do
    described_class.load!

    labrado = Diagnostics::InspectionItem.find_by(code: "tire_tread_front")
    expect(labrado).to have_attributes(value_type: "numeric", unit: "mm")
  end

  it "amarra los campos a la pieza del catalogo cuando corresponde" do
    described_class.load!

    expect(Diagnostics::InspectionItem.where.not(part_type_id: nil).count).to be_positive
  end

  it "es idempotente: correrlo dos veces no duplica" do
    described_class.load!

    expect { described_class.load! }.not_to change(Diagnostics::InspectionItem, :count)
  end
end
