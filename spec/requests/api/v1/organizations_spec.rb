require "rails_helper"

RSpec.describe "Api::V1::Organizations", type: :request do
  let(:user) { create(:user) }
  let(:json) { response.parsed_body }
  let(:headers) { auth_headers_for(user) }

  let(:valid_attributes) do
    { organization: { kind: "workshop", name: "Mecanico Juan", city: "Bogota" } }
  end

  it "responde 401 sin token" do
    post "/api/v1/organizations", params: valid_attributes, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  # Un tecnico independiente es un taller de una sola persona: se registra el
  # mismo y queda como owner, sin que nadie lo invite.
  it "deja al creador como unico miembro, con rol owner y ya aceptado" do
    post "/api/v1/organizations", params: valid_attributes, as: :json, headers: headers

    expect(response).to have_http_status(:created)
    membership = Identity::Membership.find_by(user: user)
    expect(membership).to have_attributes(role: "owner")
    expect(membership.accepted_at).to be_present
    expect(membership.organization.memberships.count).to eq(1)
  end

  it "la organizacion nace pendiente de verificacion" do
    post "/api/v1/organizations", params: valid_attributes, as: :json, headers: headers

    expect(json).to include("status" => "pending")
  end

  it "no crea nada si los datos no sirven" do
    attributes = { organization: { kind: "workshop", name: "" } }

    expect { post "/api/v1/organizations", params: attributes, as: :json, headers: headers }
      .not_to change(Identity::Organization, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "explica que campo falta" do
    post "/api/v1/organizations", params: { organization: { kind: "workshop", name: "" } },
      as: :json, headers: headers

    expect(json["errors"]).to have_key("name")
  end
end
