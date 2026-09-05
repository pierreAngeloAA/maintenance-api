require "rails_helper"

RSpec.describe Identity::Membership, type: :model do
  it "es valida con los atributos de la factory" do
    expect(build(:membership)).to be_valid
  end

  it "rechaza un rol que no existe" do
    membership = build(:membership)
    membership.role = "presidente"

    expect(membership).not_to be_valid
  end

  it "no permite dos membresias de la misma persona en la misma organizacion" do
    membership = create(:membership)

    expect(build(:membership, user: membership.user, organization: membership.organization))
      .not_to be_valid
  end

  it "permite a la misma persona pertenecer a organizaciones distintas" do
    user = create(:user)
    create(:membership, user: user)

    expect(build(:membership, user: user, organization: create(:organization, :store)))
      .to be_valid
  end

  describe "aceptacion" do
    it "una membresia aceptada esta en el scope accepted" do
      membership = create(:membership)

      expect(described_class.accepted).to include(membership)
    end

    it "una membresia invitada y sin aceptar no esta en el scope accepted" do
      membership = create(:membership, :invited)

      expect(described_class.accepted).not_to include(membership)
    end
  end
end
