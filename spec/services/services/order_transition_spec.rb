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

  # El servicio que ve el cliente y la orden que ve el taller son dos filas
  # distintas. Si solo se mueve la orden, el cliente ve "asignado" mientras el
  # tecnico ya esta trabajando en su moto.
  describe "estado visible para el cliente" do
    it "pasa la solicitud a en proceso cuando el taller arranca el trabajo" do
      described_class.new(order, "in_progress").call

      expect(order.request.reload.status).to eq("in_progress")
    end

    it "una solicitud en proceso ya no se puede tomar" do
      described_class.new(order, "in_progress").call

      expect(order.request.reload).not_to be_open
    end

    it "al cerrar el trabajo la solicitud queda completada" do
      described_class.new(order, "in_progress").call
      described_class.new(order.reload, "completed").call

      expect(order.request.reload.status).to eq("completed")
    end

    it "cancelar desde en proceso deja la solicitud cancelada" do
      described_class.new(order, "in_progress").call
      described_class.new(order.reload, "canceled").call

      expect(order.request.reload.status).to eq("canceled")
    end
  end
end
