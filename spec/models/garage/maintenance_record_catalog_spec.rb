require "rails_helper"

# Hoy `part_brand` es texto libre: "DID", "did", "D.I.D." y "cadena china" son
# cuatro marcas distintas para la base de datos, y con eso no se aprende nada.
# Enlazar el repuesto al catalogo es lo que hace contestable la pregunta que
# ninguna API externa responde: cuanto dura *esa* marca, en *esa* ciudad, en
# *ese* vehiculo.
RSpec.describe Garage::MaintenanceRecord, "repuesto del catalogo", type: :model do
  let(:vehicle) { create(:vehicle) }
  let(:part_type) { create(:part_type, applicable_vehicle_types: [ vehicle.vehicle_type ]) }
  let(:product) { create(:product, part_type: part_type, brand: "Bosch") }

  def record_with(**attributes)
    build(:maintenance_record, vehicle: vehicle, part_type: part_type, **attributes)
  end

  it "enlaza el repuesto que se instalo" do
    record = record_with(catalog_product: product)
    record.save!

    expect(record.catalog_product).to eq(product)
  end

  # La marca se copia, no se referencia.
  it "copia la marca del producto en vez de confiar en lo que escriban" do
    record = record_with(catalog_product: product, part_brand: "bosh mal escrito")
    record.save!

    expect(record.part_brand).to eq("Bosch")
  end

  # El historial del vehiculo no puede depender de que un almacen siga vendiendo
  # algo.
  it "sobrevive si el almacen borra el producto, conservando la marca" do
    record = record_with(catalog_product: product)
    record.save!

    product.destroy

    expect(record.reload).to have_attributes(catalog_product_id: nil, part_brand: "Bosch")
  end

  # Un repuesto comprado por fuera de la app sigue siendo un registro valido.
  it "acepta un mantenimiento sin producto, con la marca en texto libre" do
    record = record_with(catalog_product: nil, part_brand: "marca del barrio")

    expect(record).to be_valid
  end

  # Registrar unas pastillas como si fueran una cadena ensuciaria justo el dato
  # que hace valioso el enlace.
  it "rechaza un producto que es de otra pieza" do
    otro = create(:product, part_type: create(:part_type))

    expect(record_with(catalog_product: otro)).not_to be_valid
  end

  it "acepta un producto sin pieza asignada" do
    accesorio = create(:product, part_type: nil, brand: "Generico")

    expect(record_with(catalog_product: accesorio)).to be_valid
  end

  it "distingue los registros que vienen del catalogo" do
    del_catalogo = record_with(catalog_product: product)
    del_catalogo.save!
    record_with(part_brand: "suelta").save!

    expect(described_class.from_catalog).to contain_exactly(del_catalogo)
  end
end
