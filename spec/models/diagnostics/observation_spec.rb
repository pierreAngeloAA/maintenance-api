require "rails_helper"

RSpec.describe Diagnostics::Observation, type: :model do
  let(:inspection) { create(:inspection) }
  let(:item) { create(:inspection_item, template: inspection.template) }

  def observation_for(item, **values)
    build(:observation, inspection: inspection, item: item, **values)
  end

  it "guarda una medicion numerica" do
    expect(observation_for(item, numeric_value: 4.5)).to be_valid
  end

  # La regla que sostiene todo el producto: si el tecnico pudiera escribir
  # "llantas regulares" se perderia la velocidad de desgaste.
  it "exige el valor del tipo que pide el item" do
    expect(observation_for(item, numeric_value: nil, notes: "regulares")).not_to be_valid
  end

  it "rechaza una medicion por encima del maximo del item" do
    expect(observation_for(item, numeric_value: 99)).not_to be_valid
  end

  it "rechaza una medicion por debajo del minimo del item" do
    expect(observation_for(item, numeric_value: -1)).not_to be_valid
  end

  it "acepta una escala dentro de 1 a 4" do
    escala = create(:inspection_item, :scale, template: inspection.template)

    expect(observation_for(escala, scale_value: 3)).to be_valid
  end

  it "rechaza una escala fuera de 1 a 4" do
    escala = create(:inspection_item, :scale, template: inspection.template)

    expect(observation_for(escala, scale_value: 9)).not_to be_valid
  end

  it "acepta un booleano en falso" do
    logico = create(:inspection_item, :boolean, template: inspection.template)

    expect(observation_for(logico, boolean_value: false)).to be_valid
  end

  it "hereda la pieza del item" do
    con_pieza = create(:inspection_item, template: inspection.template,
      part_type: create(:part_type))

    observation = observation_for(con_pieza, numeric_value: 5)
    observation.save!

    expect(observation.part_type_id).to eq(con_pieza.part_type_id)
  end

  it "no permite medir dos veces el mismo campo" do
    create(:observation, inspection: inspection, item: item, numeric_value: 4)

    expect(observation_for(item, numeric_value: 5)).not_to be_valid
  end

  it "devuelve el valor segun el tipo del item" do
    observation = observation_for(item, numeric_value: 4.5)

    expect(observation.value).to eq(4.5)
  end

  # La severidad es interpretacion, no el dato. Exigirla duplicaria los toques
  # por campo y el tecnico esta de pie, con el celular en una mano.
  it "acepta una medicion sin severidad" do
    expect(observation_for(item, numeric_value: 4.5, severity: nil)).to be_valid
  end

  it "rechaza una severidad que no existe" do
    observation = observation_for(item, numeric_value: 4.5)
    observation.severity = "gravisimo"

    expect(observation).not_to be_valid
  end

  describe "#value segun el tipo del campo" do
    it "devuelve la escala" do
      escala = create(:inspection_item, :scale, template: inspection.template)

      expect(observation_for(escala, scale_value: 3).value).to eq(3)
    end

    it "devuelve el booleano" do
      logico = create(:inspection_item, :boolean, template: inspection.template)

      expect(observation_for(logico, boolean_value: false).value).to be(false)
    end

    it "devuelve la fecha" do
      fecha = create(:inspection_item, template: inspection.template,
        value_type: "date", unit: nil, minimum: nil, maximum: nil)

      expect(observation_for(fecha, numeric_value: nil, date_value: Date.new(2024, 5, 1)).value)
        .to eq(Date.new(2024, 5, 1))
    end

    it "exige la fecha si el campo es de fecha" do
      fecha = create(:inspection_item, template: inspection.template,
        value_type: "date", unit: nil, minimum: nil, maximum: nil)

      expect(observation_for(fecha, numeric_value: nil, date_value: nil)).not_to be_valid
    end
  end
end
