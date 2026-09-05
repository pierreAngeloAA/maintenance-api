require "rails_helper"

RSpec.describe Garage::VehicleAccessGrant, type: :model do
  it "es valido con los atributos de la factory" do
    expect(build(:vehicle_access_grant)).to be_valid
  end

  it "rechaza un nivel de acceso que no existe" do
    grant = build(:vehicle_access_grant)
    grant.access_level = "admin"

    expect(grant).not_to be_valid
  end

  it "no permite dos permisos vigentes de la misma organizacion sobre el mismo vehiculo" do
    grant = create(:vehicle_access_grant)

    expect(build(:vehicle_access_grant, vehicle: grant.vehicle, organization: grant.organization))
      .not_to be_valid
  end

  # Revocado uno, se puede volver a otorgar: es un permiso temporal, no una lista negra.
  it "permite volver a otorgar despues de revocar" do
    grant = create(:vehicle_access_grant, :revoked)

    expect(build(:vehicle_access_grant, vehicle: grant.vehicle, organization: grant.organization))
      .to be_valid
  end

  describe "vigencia" do
    it "un permiso sin vencimiento sigue vigente" do
      expect(described_class.active).to include(create(:vehicle_access_grant))
    end

    it "un permiso vencido deja de estar vigente" do
      expect(described_class.active).not_to include(create(:vehicle_access_grant, :expired))
    end

    it "un permiso revocado deja de estar vigente" do
      expect(described_class.active).not_to include(create(:vehicle_access_grant, :revoked))
    end

    it "un permiso con vencimiento futuro sigue vigente" do
      grant = create(:vehicle_access_grant, expires_at: 1.day.from_now)

      expect(described_class.active).to include(grant)
    end
  end

  it "se va con el vehiculo" do
    grant = create(:vehicle_access_grant)

    expect { grant.vehicle.destroy }.to change(described_class, :count).by(-1)
  end

  it "se va con la organizacion" do
    grant = create(:vehicle_access_grant)

    expect { grant.organization.destroy }.to change(described_class, :count).by(-1)
  end
end
