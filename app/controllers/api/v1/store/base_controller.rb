module Api
  module V1
    module Store
      # Todo lo que cuelga de /store exige estar actuando en nombre de un
      # almacen. Sin contexto de organizacion la peticion no tiene sentido, y
      # responder 200 con lista vacia lo disimularia.
      class BaseController < ApplicationController
        before_action :require_store_context

        private

        def require_store_context
          return if Current.store?

          render json: { error: "forbidden" }, status: :forbidden
        end
      end
    end
  end
end
