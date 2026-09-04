module Api
  module V1
    class SessionsController < ApplicationController
      allow_unauthenticated_access only: :create

      def create
        user = User.find_by(email: session_params[:email].to_s.strip.downcase)

        # Mismo error para correo inexistente y contrasena equivocada: decir cual
        # de los dos fallo revelaria quien esta registrado.
        if user&.authenticate(session_params[:password])
          render json: { user: UserSerializer.call(user), token: user.sessions.create!.token },
            status: :created
        else
          render json: { error: "invalid_credentials" }, status: :unauthorized
        end
      end

      def destroy
        current_session.destroy!

        head :no_content
      end

      private

      def session_params
        underscored_params.require(:session).permit(:email, :password)
      end
    end
  end
end
