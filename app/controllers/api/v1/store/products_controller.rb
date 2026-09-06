module Api
  module V1
    module Store
      # El catalogo del almacen. Cada uno ve y edita solo el suyo.
      class ProductsController < BaseController
        # El alcance ya lo pone la consulta: los productos de esta organizacion.
        skip_authorization only: [ :index, :create ]

        def index
          products = catalog.includes(:part_type, :fitments).order(created_at: :desc)

          render json: products.map { |product| ProductSerializer.call(product) }
        end

        def create
          product = catalog.new(product_params)

          if product.save
            render json: ProductSerializer.call(product), status: :created
          else
            render json: { errors: camelized_errors(product) }, status: :unprocessable_content
          end
        end

        def update
          product = catalog.find(params[:id])
          authorize ProductPolicy.manage?(product)
          return if performed?

          if product.update(product_params)
            render json: ProductSerializer.call(product)
          else
            render json: { errors: camelized_errors(product) }, status: :unprocessable_content
          end
        end

        private

        # El catalogo de otro almacen no existe para este: 404, no 403.
        def catalog
          Catalog::Product.where(organization: Current.organization)
        end

        def product_params
          underscored_params.require(:product).permit(
            :part_type_id, :name, :brand, :sku, :description,
            :unit_price_cents, :currency, :stock_quantity, :status
          )
        end
      end
    end
  end
end
