require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:json) { response.parsed_body }

  describe "POST /api/v1/users" do
    let(:valid_attributes) do
      { user: { email: "pierre@example.com", password: "unaClaveSegura1", name: "Pierre" } }
    end

    it "registra al usuario y lo deja con sesion iniciada" do
      expect { post "/api/v1/users", params: valid_attributes, as: :json }
        .to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["token"]).to be_present
      expect(json["user"]["email"]).to eq("pierre@example.com")
    end

    it "nunca devuelve la contrasena ni su digest" do
      post "/api/v1/users", params: valid_attributes, as: :json

      expect(json["user"]).not_to have_key("password")
      expect(json["user"]).not_to have_key("passwordDigest")
    end

    it "el token sirve de inmediato" do
      post "/api/v1/users", params: valid_attributes, as: :json

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{json['token']}" }

      expect(response).to have_http_status(:ok)
    end

    it "rechaza un correo repetido" do
      create(:user, email: "pierre@example.com")

      post "/api/v1/users", params: valid_attributes, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["email"]).to be_present
    end

    it "rechaza una contrasena corta" do
      post "/api/v1/users", params: { user: { email: "otro@example.com", password: "corta" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["password"]).to be_present
    end

    it "no exige estar autenticado" do
      post "/api/v1/users", params: valid_attributes, as: :json

      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end
