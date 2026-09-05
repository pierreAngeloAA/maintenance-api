module Api
  module V1
    class UsersController < ApplicationController
      # Registro publico.
      skip_authorization

      allow_unauthenticated_access only: :create

      def create
        user = User.new(user_params)

        if user.save
          render json: { user: UserSerializer.call(user), token: user.sessions.create!.token },
            status: :created
        else
          render json: { errors: camelized_errors(user) }, status: :unprocessable_content
        end
      end

      private

      def user_params
        underscored_params.require(:user).permit(:email, :password, :name)
      end
    end
  end
end
