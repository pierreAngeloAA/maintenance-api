require "rails_helper"

# Denegado por defecto: una accion que no declara su politica no puede pasar
# desapercibida. Fuera de produccion revienta, para que el olvido se vea en la
# suite y no en el servidor.
RSpec.describe "Denegado por defecto", type: :request do
  # Un controller de mentira, montado solo para esta prueba: no hay ninguno real
  # sin politica, que es justamente lo que se quiere garantizar.
  before do
    stub_const("DescuidadoController", Class.new(ApplicationController) do
      def self.name = "DescuidadoController"

      def show
        render json: { ok: true }
      end
    end)

    Rails.application.routes.draw do
      get "descuidado", to: "descuidado#show"
    end
  end

  after { Rails.application.reload_routes! }

  let(:user) { create(:user) }

  it "revienta si la accion nunca llamo a authorize" do
    expect { get "/descuidado", headers: auth_headers_for(user) }
      .to raise_error(Authorization::PolicyNotChecked, /descuidado#show/)
  end

  it "en produccion no revienta: la respuesta ya se rendero y no se puede renderizar dos veces" do
    allow(Rails.env).to receive(:production?).and_return(true)

    get "/descuidado", headers: auth_headers_for(user)

    expect(response).to have_http_status(:ok)
  end
end
