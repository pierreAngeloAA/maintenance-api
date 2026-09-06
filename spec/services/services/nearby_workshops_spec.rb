require "rails_helper"

RSpec.describe Services::NearbyWorkshops do
  # Bogota, Calle 100.
  let(:latitude) { 4.6533 }
  let(:longitude) { -74.0836 }

  def workshop_at(lat, lng, **attributes)
    create(:organization, latitude: lat, longitude: lng, **attributes)
  end

  it "encuentra un taller a pocos kilometros" do
    cerca = workshop_at(4.6700, -74.0800)

    expect(described_class.call(latitude: latitude, longitude: longitude)).to include(cerca)
  end

  it "descarta uno en otra ciudad" do
    # Barranquilla.
    lejos = workshop_at(10.9639, -74.7964)

    expect(described_class.call(latitude: latitude, longitude: longitude)).not_to include(lejos)
  end

  it "descarta los talleres suspendidos" do
    suspendido = workshop_at(4.6700, -74.0800, status: "suspended")

    expect(described_class.call(latitude: latitude, longitude: longitude)).not_to include(suspendido)
  end

  it "no devuelve almacenes" do
    almacen = create(:organization, :store, latitude: 4.6700, longitude: -74.0800)

    expect(described_class.call(latitude: latitude, longitude: longitude)).not_to include(almacen)
  end

  it "descarta los que no tienen ubicacion" do
    sin_ubicacion = create(:organization, latitude: nil, longitude: nil)

    expect(described_class.call(latitude: latitude, longitude: longitude)).not_to include(sin_ubicacion)
  end

  it "sin ubicacion de referencia no devuelve nada" do
    workshop_at(4.6700, -74.0800)

    expect(described_class.call(latitude: nil, longitude: nil)).to be_empty
  end

  it "respeta el radio que se le pida" do
    a_ocho_km = workshop_at(4.7250, -74.0836)

    expect(described_class.call(latitude: latitude, longitude: longitude, radius_km: 3))
      .not_to include(a_ocho_km)
  end
end
