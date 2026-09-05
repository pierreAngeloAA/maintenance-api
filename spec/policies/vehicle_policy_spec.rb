require "rails_helper"

RSpec.describe VehiclePolicy do
  let(:owner) { create(:user) }
  let(:vehicle) { create(:vehicle, user: owner) }
  let(:workshop) { create(:organization) }

  after { Current.reset }

  def acting_as_owner
    Current.user = owner
  end

  def acting_as_workshop(organization = workshop)
    membership = create(:membership, organization: organization, role: "technician")
    Current.user = membership.user
    Current.membership = membership
    Current.organization = organization
  end

  describe ".read?" do
    it "el dueno siempre puede leer su vehiculo" do
      acting_as_owner

      expect(described_class.read?(vehicle)).to be(true)
    end

    it "un taller con permiso vigente puede leer" do
      create(:vehicle_access_grant, :read_only, vehicle: vehicle, organization: workshop)
      acting_as_workshop

      expect(described_class.read?(vehicle)).to be(true)
    end

    it "un taller sin permiso no puede leer" do
      acting_as_workshop

      expect(described_class.read?(vehicle)).to be(false)
    end

    it "un taller con el permiso revocado no puede leer" do
      create(:vehicle_access_grant, :revoked, vehicle: vehicle, organization: workshop)
      acting_as_workshop

      expect(described_class.read?(vehicle)).to be(false)
    end

    it "un usuario cualquiera no puede leer el vehiculo de otro" do
      Current.user = create(:user)

      expect(described_class.read?(vehicle)).to be(false)
    end
  end

  describe ".write?" do
    it "el dueno siempre puede escribir" do
      acting_as_owner

      expect(described_class.write?(vehicle)).to be(true)
    end

    it "un taller con permiso de escritura puede" do
      create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)
      acting_as_workshop

      expect(described_class.write?(vehicle)).to be(true)
    end

    # Leer el historial no es lo mismo que escribir en el.
    it "un taller con permiso de solo lectura no puede escribir" do
      create(:vehicle_access_grant, :read_only, vehicle: vehicle, organization: workshop)
      acting_as_workshop

      expect(described_class.write?(vehicle)).to be(false)
    end

    it "un taller con el permiso vencido no puede escribir" do
      create(:vehicle_access_grant, :expired, vehicle: vehicle, organization: workshop)
      acting_as_workshop

      expect(described_class.write?(vehicle)).to be(false)
    end

    it "el permiso sobre un vehiculo no sirve para otro" do
      create(:vehicle_access_grant, vehicle: vehicle, organization: workshop)
      acting_as_workshop

      expect(described_class.write?(create(:vehicle))).to be(false)
    end
  end
end
