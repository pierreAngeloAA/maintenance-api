require "rails_helper"

RSpec.describe Diagnostics::InspectionTemplate, type: :model do
  it "no permite dos plantillas con el mismo codigo y version" do
    template = create(:inspection_template)

    expect(build(:inspection_template, code: template.code, version: template.version))
      .not_to be_valid
  end

  it "permite la version siguiente del mismo checklist" do
    template = create(:inspection_template)

    expect(build(:inspection_template, code: template.code, version: 2)).to be_valid
  end

  it "rechaza una clase de vehiculo que no soportamos" do
    expect(build(:inspection_template, vehicle_type: "boat")).not_to be_valid
  end

  describe ".current_for" do
    it "devuelve la ultima version publicada de esa clase de vehiculo" do
      create(:inspection_template, code: "monthly", version: 1, vehicle_type: "car")
      v2 = create(:inspection_template, code: "monthly", version: 2, vehicle_type: "car")

      expect(described_class.current_for("car")).to eq(v2)
    end

    it "ignora las que no se han publicado" do
      publicada = create(:inspection_template, code: "monthly", version: 1, vehicle_type: "car")
      create(:inspection_template, :draft, code: "monthly", version: 2, vehicle_type: "car")

      expect(described_class.current_for("car")).to eq(publicada)
    end

    it "no mezcla clases de vehiculo" do
      create(:inspection_template, vehicle_type: "car")

      expect(described_class.current_for("motorcycle")).to be_nil
    end
  end

  # Una plantilla usada no se borra: las mediciones viejas tienen que seguir
  # siendo interpretables.
  it "no se puede borrar si ya se uso" do
    inspection = create(:inspection)

    expect(inspection.template.destroy).to be(false)
  end
end
