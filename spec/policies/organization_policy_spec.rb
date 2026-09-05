require "rails_helper"

RSpec.describe OrganizationPolicy do
  let(:organization) { create(:organization) }

  after { Current.reset }

  def acting_as(membership)
    Current.membership = membership
    Current.organization = membership&.organization
  end

  describe ".manage?" do
    it "permite al dueno" do
      acting_as(create(:membership, organization: organization, role: "owner"))

      expect(described_class.manage?(organization)).to be(true)
    end

    it "permite a un administrador" do
      acting_as(create(:membership, organization: organization, role: "admin"))

      expect(described_class.manage?(organization)).to be(true)
    end

    it "no permite a un vendedor" do
      acting_as(create(:membership, organization: organization, role: "clerk"))

      expect(described_class.manage?(organization)).to be(false)
    end

    it "no permite a un tecnico" do
      acting_as(create(:membership, organization: organization, role: "technician"))

      expect(described_class.manage?(organization)).to be(false)
    end

    # Ser dueno de un taller no da permisos sobre otro.
    it "no permite administrar una organizacion distinta a la del contexto activo" do
      acting_as(create(:membership, role: "owner"))

      expect(described_class.manage?(organization)).to be(false)
    end

    it "no permite sin contexto de organizacion" do
      acting_as(nil)

      expect(described_class.manage?(organization)).to be(false)
    end
  end
end
