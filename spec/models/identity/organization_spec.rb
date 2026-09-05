require "rails_helper"

RSpec.describe Identity::Organization, type: :model do
  describe "atributos basicos" do
    it "es valida con los atributos de la factory" do
      expect(build(:organization)).to be_valid
    end

    it "exige nombre" do
      expect(build(:organization, name: nil)).not_to be_valid
    end

    it "rechaza una clase de organizacion que no soportamos" do
      organization = build(:organization)
      organization.kind = "airline"

      expect(organization).not_to be_valid
    end

    it "arranca pendiente de verificacion si no se dice otra cosa" do
      expect(described_class.new.status).to eq("pending")
    end

    it "no permite dos organizaciones con el mismo NIT" do
      create(:organization, nit: "900123456")

      expect(build(:organization, nit: "900123456")).not_to be_valid
    end

    it "permite varias organizaciones sin NIT" do
      create(:organization, nit: nil)

      expect(build(:organization, nit: nil)).to be_valid
    end
  end

  describe "membresias" do
    it "se lleva sus membresias al destruirse" do
      membership = create(:membership)

      expect { membership.organization.destroy }
        .to change(Identity::Membership, :count).by(-1)
    end
  end
end
