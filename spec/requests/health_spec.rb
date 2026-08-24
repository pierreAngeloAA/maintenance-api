require "rails_helper"

RSpec.describe "Health check", type: :request do
  describe "GET /up" do
    it "responde 200 cuando la aplicacion levanta correctamente" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end
  end
end
