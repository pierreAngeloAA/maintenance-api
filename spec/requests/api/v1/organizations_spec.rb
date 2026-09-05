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

  describe "PATCH /api/v1/organizations/:id" do
    let(:organization) { create(:organization, name: "Taller El Rayo") }

    def patch_name(role:)
      create(:membership, user: user, organization: organization, role: role)

      patch "/api/v1/organizations/#{organization.id}",
        params: { organization: { name: "Taller Nuevo" } }, as: :json,
        headers: headers.merge("X-Organization-Id" => organization.id.to_s)
    end

    it "el dueno puede cambiar los datos" do
      patch_name(role: "owner")

      expect(response).to have_http_status(:ok)
      expect(organization.reload.name).to eq("Taller Nuevo")
    end

    it "un vendedor no puede: vende, pero no administra el negocio" do
      patch_name(role: "clerk")

      expect(response).to have_http_status(:forbidden)
      expect(organization.reload.name).to eq("Taller El Rayo")
    end

    it "sin contexto de organizacion tampoco, aunque sea el dueno" do
      create(:membership, user: user, organization: organization, role: "owner")

      patch "/api/v1/organizations/#{organization.id}",
        params: { organization: { name: "Taller Nuevo" } }, as: :json, headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it "responde 404 si la organizacion no existe" do
      patch "/api/v1/organizations/0", params: { organization: { name: "X" } },
        as: :json, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "explica que campo esta mal" do
      create(:membership, user: user, organization: organization, role: "owner")

      patch "/api/v1/organizations/#{organization.id}",
        params: { organization: { name: "" } }, as: :json,
        headers: headers.merge("X-Organization-Id" => organization.id.to_s)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("name")
    end
  end
end
