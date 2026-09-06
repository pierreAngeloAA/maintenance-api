module Api
  module V1
    module Store
      # Para que vehiculos sirve cada producto.
      class FitmentsController < BaseController
        def index
          authorize ProductPolicy.manage?(product)
          return if performed?

          render json: product.fitments.map { |fitment| FitmentSerializer.call(fitment) }
        end

        def create
          authorize ProductPolicy.manage?(product)
          return if performed?

          fitment = product.fitments.new(fitment_params)

          if fitment.save
            render json: FitmentSerializer.call(fitment), status: :created
          else
            render json: { errors: camelized_errors(fitment) }, status: :unprocessable_content
          end
        end

        def destroy
          authorize ProductPolicy.manage?(product)
          return if performed?

          product.fitments.find(params[:id]).destroy!

          head :no_content
        end

        private

        def product
          @product ||= Catalog::Product
            .where(organization: Current.organization)
            .find(params[:product_id])
        end

        def fitment_params
          underscored_params.require(:fitment).permit(
            :vehicle_type, :make, :model, :year_from, :year_to
          )
        end
      end
    end
  end
end
