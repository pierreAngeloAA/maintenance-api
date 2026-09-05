require "rails_helper"

RSpec.describe "Api::V1::Me", type: :request do
  let(:user) { create(:user) }
  let(:json) { response.parsed_body }
  let(:headers) { auth_headers_for(user) }

  it "responde 401 sin token" do
    get "/api/v1/me"

    expect(response).to have_http_status(:unauthorized)
  end

  describe "contextos disponibles" do
    it "un usuario sin membresias solo tiene el contexto de cliente" do
      get "/api/v1/me", headers: headers

      expect(json["contexts"]).to eq([ { "kind" => "client" } ])
    end

    it "devuelve un contexto por cada membresia aceptada, con su rol" do
      workshop = create(:organization, name: "Taller El Rayo")
      store = create(:organization, :store, name: "Repuestos JC")
      create(:membership, user: user, organization: workshop, role: "owner")
      create(:membership, user: user, organization: store, role: "clerk")

      get "/api/v1/me", headers: headers

      expect(json["contexts"]).to contain_exactly(
        { "kind" => "client" },
        { "kind" => "workshop", "organizationId" => workshop.id,
          "name" => "Taller El Rayo", "role" => "owner" },
        { "kind" => "store", "organizationId" => store.id,
          "name" => "Repuestos JC", "role" => "clerk" }
      )
    end

    it "no incluye las membresias invitadas que aun no se aceptan" do
      create(:membership, :invited, user: user)

      get "/api/v1/me", headers: headers

      expect(json["contexts"]).to eq([ { "kind" => "client" } ])
    end
  end

  it "sigue devolviendo los datos del usuario" do
    get "/api/v1/me", headers: headers

    expect(json["user"]).to include("email" => user.email)
  end
end
