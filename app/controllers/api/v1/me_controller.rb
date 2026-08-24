module Api
  module V1
    class MeController < ApplicationController
      def show
        render json: UserSerializer.call(current_user)
      end
    end
  end
end
