module Api
  module V1
    module Workshop
      # Todo lo que cuelga de /workshop exige estar actuando en nombre de un
      # taller. Sin contexto de organizacion no es que no haya nada que ver: es
      # que la peticion no tiene sentido, y responder 200 con lista vacia lo
      # disimularia.
      class BaseController < ApplicationController
        before_action :require_workshop_context

        private

        def require_workshop_context
          return if Current.workshop?

          render json: { error: "forbidden" }, status: :forbidden
        end
      end
    end
  end
end
