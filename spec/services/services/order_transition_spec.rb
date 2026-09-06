require "rails_helper"

RSpec.describe Services::OrderTransition do
  let(:workshop) { create(:organization) }
  let(:technician) { create(:membership, organization: workshop, role: "technician").user }
  let(:offer) { create(:service_offer, organization: workshop) }
  let(:order) { Services::OfferAcceptance.new(offer, technician).call.order }

  it "avanza de asignada a en camino" do
    expect(described_class.new(order, "en_route").call).to be_success
    expect(order.reload.status).to eq("en_route")
  end

  it "anota cuando empezo el trabajo" do
    described_class.new(order, "in_progress").call

    expect(order.reload.started_at).to be_present
  end

  it "no deja saltar de asignada a completada" do
    result = described_class.new(order, "completed").call

    expect(result.error).to eq(:invalid_transition)
    expect(order.reload.status).to eq("assigned")
  end

  it "no deja revivir una orden completada" do
    described_class.new(order, "in_progress").call
    described_class.new(order, "completed").call

    result = described_class.new(order, "in_progress").call

    expect(result.error).to eq(:invalid_transition)
  end

  # El taller entra a la historia del vehiculo mientras dura el trabajo, no para siempre.
  it "al completar revoca el permiso sobre el vehiculo" do
    described_class.new(order, "in_progress").call
    described_class.new(order, "completed").call

    expect(Garage::VehicleAccessGrant.active.where(service_order: order)).to be_empty
  end

  it "al cancelar tambien revoca el permiso" do
    described_class.new(order, "canceled").call

    expect(Garage::VehicleAccessGrant.active.where(service_order: order)).to be_empty
    expect(order.request.reload.status).to eq("canceled")
  end

  it "al completar cierra la solicitud" do
    described_class.new(order, "in_progress").call
    described_class.new(order, "completed").call

    expect(order.request.reload.status).to eq("completed")
  end
end
