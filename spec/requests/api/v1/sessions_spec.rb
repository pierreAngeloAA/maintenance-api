require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let(:json) { response.parsed_body }
  let!(:user) { create(:user, email: "pierre@example.com", password: "unaClaveSegura1") }

  describe "POST /api/v1/sessions" do
    it "inicia sesion y devuelve el token" do
      post "/api/v1/sessions", params: { session: { email: "pierre@example.com", password: "unaClaveSegura1" } }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["token"]).to be_present
      expect(json["user"]["email"]).to eq("pierre@example.com")
    end

    it "acepta el correo con mayusculas y espacios" do
      post "/api/v1/sessions", params: { session: { email: "  PIERRE@example.com ", password: "unaClaveSegura1" } }, as: :json

      expect(response).to have_http_status(:created)
    end

    it "rechaza la contrasena equivocada sin decir cual dato fallo" do
      post "/api/v1/sessions", params: { session: { email: "pierre@example.com", password: "otra" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("invalid_credentials")
    end

    it "responde igual cuando el correo no existe: no revela quien esta registrado" do
      post "/api/v1/sessions", params: { session: { email: "nadie@example.com", password: "loquesea" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("invalid_credentials")
    end
  end

  describe "DELETE /api/v1/sessions" do
    it "cierra la sesion y el token deja de servir" do
      headers = auth_headers_for(user)

      expect { delete "/api/v1/sessions", headers: headers }.to change(Session, :count).by(-1)
      expect(response).to have_http_status(:no_content)

      get "/api/v1/me", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "no cierra las otras sesiones del usuario" do
      otra = user.sessions.create!
      delete "/api/v1/sessions", headers: auth_headers_for(user)

      expect(Session.exists?(otra.id)).to be(true)
    end
  end

  describe "GET /api/v1/me" do
    it "devuelve el usuario de la sesion" do
      get "/api/v1/me", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json["email"]).to eq("pierre@example.com")
    end

    it "responde 401 sin token" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "responde 401 con un token inventado" do
      get "/api/v1/me", headers: { "Authorization" => "Bearer inventado" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "responde 401 con una cabecera que no es Bearer" do
      get "/api/v1/me", headers: { "Authorization" => "Basic abc123" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
