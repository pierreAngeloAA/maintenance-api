module Api
  module V1
    module Workshop
      # Los servicios que el taller puede tomar.
      class ServiceOffersController < BaseController
        # El alcance ya lo pone la consulta: las ofertas de esta organizacion.
        skip_authorization

        def index
          offers = Services::Offer.open
            .where(organization: Current.organization)
            .includes(request: :vehicle)
            .order(created_at: :desc)

          render json: offers.map { |offer| ServiceOfferSerializer.call(offer) }
        end

        # Tomar el servicio. Es la operacion que crea la orden y, con ella, el
        # permiso del taller sobre el vehiculo.
        def update
          result = Services::OfferAcceptance.new(offer, current_user).call

          if result.success?
            render json: ServiceOrderSerializer.call(result.order), status: :created
          else
            render json: { error: result.error }, status: :unprocessable_content
          end
        end

        # Pasar de largo. Se registra en vez de solo ignorarla: saber que ofertas
        # rechaza un taller es informacion, no ruido.
        def destroy
          offer.update!(status: "rejected")

          head :no_content
        end

        private

        def offer
          @offer ||= Services::Offer.where(organization: Current.organization).find(params[:id])
        end
      end
    end
  end
end
