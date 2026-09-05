module Api
  module V1
    class MeController < ApplicationController
      # Devuelve lo del propio usuario de la sesion.
      skip_authorization

      def show
        render json: {
          user: UserSerializer.call(current_user),
          # En que contextos puede actuar: con uno solo la app entra directo,
          # con dos o mas muestra el selector.
          contexts: ContextSerializer.call(current_user),
          # En cual esta actuando ahora, segun el header X-Organization-Id. Le
          # sirve a la app para confirmar que el servidor entendio lo mismo.
          activeContext: active_context
        }
      end

      private

      def active_context
        return ContextSerializer::CLIENT if Current.client?

        ContextSerializer.for_membership(Current.membership)
      end
    end
  end
end
