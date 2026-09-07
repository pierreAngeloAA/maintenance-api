require "rails_helper"

RSpec.describe Catalog::Product, type: :model do
  it "es valido con los atributos de la factory" do
    expect(build(:product)).to be_valid
  end

  it "exige nombre y marca" do
    expect(build(:product, name: nil)).not_to be_valid
    expect(build(:product, brand: nil)).not_to be_valid
  end

  it "rechaza un precio negativo" do
    expect(build(:product, unit_price_cents: -1)).not_to be_valid
  end

  # Un taller no publica catalogo: para eso esta el almacen.
  it "solo lo puede publicar un almacen" do
    expect(build(:product, organization: create(:organization))).not_to be_valid
  end

  describe "SKU" do
    it "no se repite dentro del mismo almacen" do
      product = create(:product, sku: "ABC-1")

      expect(build(:product, organization: product.organization, sku: "ABC-1")).not_to be_valid
    end

    # Dos almacenes pueden usar el mismo codigo para cosas distintas.
    it "puede repetirse entre almacenes distintos" do
      create(:product, sku: "ABC-1")

      expect(build(:product, sku: "ABC-1")).to be_valid
    end

    it "es opcional" do
      create(:product, sku: nil)

      expect(build(:product, sku: nil)).to be_valid
    end

    it "se normaliza a mayusculas" do
      expect(create(:product, sku: " abc-1 ").sku).to eq("ABC-1")
    end
  end

  describe "disponibilidad" do
    it "un producto publicado y con stock esta disponible" do
      expect(described_class.available).to include(create(:product))
    end

    it "un borrador no esta disponible" do
      expect(described_class.available).not_to include(create(:product, :draft))
    end

    it "sin stock no esta disponible" do
      expect(described_class.available).not_to include(create(:product, :out_of_stock))
    end
  end

  describe "para que vehiculos sirve" do
    let(:logan) { create(:vehicle, make: "Renault", model: "Logan", model_year: 2019) }

    # Un producto sin compatibilidad declarada es universal (aceite, liquido de
    # frenos), no un producto incompleto.
    it "un producto sin compatibilidad sirve para cualquier vehiculo" do
      universal = create(:product)

      expect(universal).to be_universal
      expect(described_class.for_vehicle(logan)).to include(universal)
    end

    it "un producto compatible aparece" do
      fitment = create(:fitment)

      expect(described_class.for_vehicle(logan)).to include(fitment.product)
    end

    it "un producto incompatible no aparece" do
      fitment = create(:fitment, make: "Mazda")

      expect(described_class.for_vehicle(logan)).not_to include(fitment.product)
    end

    it "basta con que una de sus compatibilidades coincida" do
      product = create(:product)
      create(:fitment, product: product, make: "Mazda")
      create(:fitment, product: product, make: "Renault", model: "Logan")

      expect(described_class.for_vehicle(logan)).to include(product)
    end
  end

  describe "vida util" do
    it "es opcional: no todo producto declara cuanto dura" do
      expect(build(:product, expected_life_usage_value: nil, expected_life_months: nil)).to be_valid
    end

    it "acepta duracion por uso y por tiempo a la vez" do
      product = build(:product, :con_vida_util)

      expect(product).to be_valid
      expect(product.expected_life_usage_value).to eq(40_000)
      expect(product.expected_life_months).to eq(24)
    end

    # Un numero sin unidad no significa nada: 40.000 puede ser km u horas de
    # motor, y la comparacion contra el historial de uso dependeria de adivinar.
    it "rechaza un valor de uso sin unidad" do
      expect(build(:product, expected_life_usage_value: 40_000,
                             expected_life_usage_unit: nil)).not_to be_valid
    end

    it "rechaza una unidad de uso que no existe" do
      expect(build(:product, expected_life_usage_value: 40_000,
                             expected_life_usage_unit: "millas")).not_to be_valid
    end

    it "rechaza una duracion de cero o negativa" do
      expect(build(:product, expected_life_months: 0)).not_to be_valid
      expect(build(:product, expected_life_usage_value: -1)).not_to be_valid
    end

    # Una unidad suelta es basura, no un error del que la manda: se limpia.
    it "descarta la unidad cuando no hay valor de uso" do
      product = create(:product, expected_life_usage_value: nil,
                                 expected_life_usage_unit: "km")

      expect(product.expected_life_usage_unit).to be_nil
    end
  end

  describe "garantia" do
    # Vida util y garantia son cosas distintas: un amortiguador puede durar
    # 60.000 km y tener 12 meses de garantia.
    it "es independiente de la vida util" do
      product = build(:product, :con_vida_util, :con_garantia)

      expect(product.expected_life_usage_value).to eq(40_000)
      expect(product.warranty_usage_value).to eq(20_000)
    end

    it "un producto sin meses ni kilometros no tiene garantia" do
      expect(build(:product)).not_to be_warranty
    end

    it "basta con los meses para que tenga garantia" do
      expect(build(:product, warranty_months: 12)).to be_warranty
    end

    it "basta con los kilometros para que tenga garantia" do
      expect(build(:product, warranty_usage_value: 20_000,
                             warranty_usage_unit: "km")).to be_warranty
    end

    it "rechaza un valor de uso sin unidad" do
      expect(build(:product, warranty_usage_value: 20_000,
                             warranty_usage_unit: nil)).not_to be_valid
    end

    it "rechaza una unidad de uso que no existe" do
      expect(build(:product, warranty_usage_value: 20_000,
                             warranty_usage_unit: "millas")).not_to be_valid
    end

    it "rechaza meses negativos" do
      expect(build(:product, warranty_months: -1)).not_to be_valid
    end
  end

  it "se lleva sus compatibilidades al borrarse" do
    fitment = create(:fitment)

    expect { fitment.product.destroy }.to change(Catalog::Fitment, :count).by(-1)
  end
end
