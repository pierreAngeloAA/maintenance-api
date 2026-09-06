require "rails_helper"

# La compatibilidad es la parte dificil del comercio de repuestos: es donde la
# gente compra mal y devuelve.
RSpec.describe Catalog::Fitment, type: :model do
  let(:logan) { create(:vehicle, vehicle_type: "car", make: "Renault", model: "Logan", model_year: 2019) }

  def matches?(fitment, vehicle = logan)
    described_class.matching(vehicle).exists?(fitment.id)
  end

  it "es valido con los atributos de la factory" do
    expect(build(:fitment)).to be_valid
  end

  it "rechaza una clase de vehiculo que no soportamos" do
    expect(build(:fitment, vehicle_type: "boat")).not_to be_valid
  end

  it "rechaza un rango de anos al reves" do
    expect(build(:fitment, year_from: 2020, year_to: 2015)).not_to be_valid
  end

  describe "coincidencia" do
    it "coincide con el vehiculo exacto" do
      expect(matches?(create(:fitment))).to be(true)
    end

    it "no coincide con otra marca" do
      expect(matches?(create(:fitment, make: "Mazda"))).to be(false)
    end

    it "no coincide con otra linea" do
      expect(matches?(create(:fitment, model: "Sandero"))).to be(false)
    end

    it "no coincide fuera del rango de anos" do
      expect(matches?(create(:fitment, year_from: 2021, year_to: 2024))).to be(false)
    end

    it "no coincide con otra clase de vehiculo" do
      moto = create(:vehicle, :motorcycle)

      expect(matches?(create(:fitment), moto)).to be(false)
    end

    # El almacen escribe "Renault" y el usuario registro "RENAULT".
    it "no distingue mayusculas en marca ni linea" do
      expect(matches?(create(:fitment, make: "RENAULT", model: "logan"))).to be(true)
    end

    # Compatibilidad gruesa: sirve para toda la marca, sin enumerar lineas.
    it "una linea nula significa cualquiera de esa marca" do
      expect(matches?(create(:fitment, model: nil))).to be(true)
    end

    it "una marca nula significa cualquiera de esa clase" do
      expect(matches?(create(:fitment, make: nil, model: nil))).to be(true)
    end

    it "sin rango de anos aplica a todos los anos" do
      expect(matches?(create(:fitment, year_from: nil, year_to: nil))).to be(true)
    end

    it "solo con ano desde, aplica de ahi en adelante" do
      expect(matches?(create(:fitment, year_from: 2015, year_to: nil))).to be(true)
      expect(matches?(create(:fitment, year_from: 2021, year_to: nil))).to be(false)
    end
  end
end
