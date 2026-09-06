require "rails_helper"

RSpec.describe Orders::Order, type: :model do
  let(:store) { create(:organization, :store) }

  def order(**attributes)
    build(:order, seller_organization: store, **attributes)
  end

  it "es valida con los atributos de la factory" do
    expect(order).to be_valid
  end

  # Un taller no vende catalogo: para eso esta el almacen.
  it "el vendedor tiene que ser un almacen" do
    expect(order(seller_organization: create(:organization))).not_to be_valid
  end

  it "rechaza un total negativo" do
    expect(order(total_cents: -1)).not_to be_valid
  end

  describe "transiciones" do
    it "de pendiente puede pasar a pagada o cancelada" do
      pendiente = order(status: "pending")

      expect(pendiente.can_transition_to?("paid")).to be(true)
      expect(pendiente.can_transition_to?("canceled")).to be(true)
    end

    it "de pendiente no puede saltar a entregada" do
      expect(order(status: "pending").can_transition_to?("delivered")).to be(false)
    end

    it "una entregada no va a ningun lado" do
      entregada = order(status: "delivered")

      expect(entregada.can_transition_to?("shipped")).to be(false)
      expect(entregada.can_transition_to?("canceled")).to be(false)
    end

    it "una cancelada tampoco" do
      expect(order(status: "canceled").can_transition_to?("paid")).to be(false)
    end
  end
end
