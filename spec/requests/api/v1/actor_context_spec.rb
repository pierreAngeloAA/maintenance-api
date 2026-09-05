require "rails_helper"

# El token dice quien eres; el header X-Organization-Id dice en nombre de quien
# actuas. El backend nunca le cree al header solo: valida la membresia siempre.
RSpec.describe "Contexto del actor", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  def get_me(organization_id)
    get "/api/v1/me", headers: headers.merge("X-Organization-Id" => organization_id.to_s)
  end

  let(:json) { response.parsed_body }

  it "sin el header, el actor es el cliente" do
    get "/api/v1/me", headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["activeContext"]).to eq({ "kind" => "client" })
  end

  it "con membresia aceptada, carga la organizacion en Current" do
    workshop = create(:organization)
    create(:membership, user: user, organization: workshop, role: "technician")

    get_me(workshop.id)

    expect(response).to have_http_status(:ok)
    expect(json["activeContext"]).to include(
      "kind" => "workshop", "organizationId" => workshop.id, "role" => "technician"
    )
  end

  it "responde 403 si no tiene membresia en esa organizacion" do
    get_me(create(:organization).id)

    expect(response).to have_http_status(:forbidden)
  end

  it "responde 403 mientras la invitacion no se acepte" do
    membership = create(:membership, :invited, user: user)

    get_me(membership.organization_id)

    expect(response).to have_http_status(:forbidden)
  end

  it "responde 403 si la organizacion esta suspendida" do
    workshop = create(:organization, :suspended)
    create(:membership, user: user, organization: workshop)

    get_me(workshop.id)

    expect(response).to have_http_status(:forbidden)
  end

  it "responde 403 si la organizacion no existe" do
    get_me(0)

    expect(response).to have_http_status(:forbidden)
  end
end
