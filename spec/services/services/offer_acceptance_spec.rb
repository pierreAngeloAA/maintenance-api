require "rails_helper"

RSpec.describe Services::OfferAcceptance do
  let(:workshop) { create(:organization) }
  let(:technician) { create(:membership, organization: workshop, role: "technician").user }
  let(:request) { create(:service_request) }
  let(:offer) { create(:service_offer, request: request, organization: workshop) }

  it "crea la orden de trabajo" do
    result = described_class.new(offer, technician).call

    expect(result).to be_success
    expect(result.order).to have_attributes(
      organization_id: workshop.id, technician_user_id: technician.id, status: "assigned"
    )
  end

  # Lo que ata todo el producto: el cliente acepta un servicio, no otorga un
  # permiso. Nadie deberia tener que entender el modelo de permisos para usar la app.
  it "crea el permiso del taller sobre el vehiculo, amarrado a la orden" do
    result = described_class.new(offer, technician).call

    grant = Garage::VehicleAccessGrant.find_by(service_order: result.order)
    expect(grant).to have_attributes(
      vehicle_id: request.vehicle_id, organization_id: workshop.id, access_level: "write"
    )
    expect(Garage::VehicleAccessGrant.active).to include(grant)
  end

  it "marca la solicitud como asignada" do
    described_class.new(offer, technician).call

    expect(request.reload.status).to eq("assigned")
  end

  it "descarta las ofertas de los demas talleres" do
    otra = create(:service_offer, request: request, organization: create(:organization))

    described_class.new(offer, technician).call

    expect(otra.reload.status).to eq("rejected")
  end

  it "no deja tomar una oferta vencida" do
    vencida = create(:service_offer, :expired, request: request, organization: workshop)

    result = described_class.new(vencida, technician).call

    expect(result.error).to eq(:offer_not_open)
    expect(Services::Order.count).to eq(0)
  end

  it "no deja tomar una solicitud que ya no esta pendiente" do
    request.update!(status: "canceled")

    result = described_class.new(offer, technician).call

    expect(result.error).to eq(:request_not_open)
  end

  # El indice unico sobre request_id es lo que lo garantiza, no la revision previa.
  it "si dos talleres aceptan, solo uno gana" do
    otro_taller = create(:organization)
    otra_oferta = create(:service_offer, request: request, organization: otro_taller)
    otro_tecnico = create(:membership, organization: otro_taller, role: "technician").user

    primero = described_class.new(offer, technician).call

    # Se simula que el segundo taller acepta antes de ver el rechazo: es la
    # carrera real. Lo que lo frena es el indice unico sobre request_id, no que
    # el codigo revise primero.
    request.reload.update_columns(status: "pending")
    otra_oferta.update_columns(status: "offered")

    segundo = described_class.new(otra_oferta.reload, otro_tecnico).call

    expect(primero).to be_success
    expect(segundo.error).to eq(:already_taken)
    expect(Services::Order.count).to eq(1)
  end
end
