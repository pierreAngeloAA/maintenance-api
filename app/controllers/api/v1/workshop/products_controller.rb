module Api
  module V1
    module Workshop
      # La vitrina del taller: el catalogo disponible de todos los almacenes.
      #
      # La del cliente cuelga de un vehiculo propio y filtra por compatibilidad
      # con el. El taller compra distinto —compra para un trabajo, muchas veces
      # de un vehiculo que no esta registrado en la plataforma— asi que el
      # vehiculo es un filtro opcional y no la ruta. Colgarla de un `vehicle_id`
      # lo obligaria a inventarse un vehiculo para poder comprar aceite.
      class ProductsController < BaseController
        # El alcance ya lo pone la consulta: solo lo publicado y con stock.
        skip_authorization

        def index
          render json: catalog.map { |product| ProductSerializer.call(product) }
        end

        private

        def catalog
          scope = Catalog::Product.available.includes(:part_type, :fitments)
          scope = scope.for_vehicle(vehicle) if filters[:vehicle_id].present?
          scope = scope.where(part_type_id: filters[:part_type_id]) if filters[:part_type_id].present?
          scope = scope.search(filters[:q]) if filters[:q].to_s.strip.present?

          scope.order(:unit_price_cents)
        end

        # El frontend manda camelCase; adentro se habla snake_case. La traduccion
        # vive en el concern, no repartida por los controllers.
        def filters
          @filters ||= underscored_params.slice(:vehicle_id, :part_type_id, :q)
        end

        # Un vehiculo sin permiso vigente responde 404 y no 403: contestar
        # distinto delataria que existe, y un taller no tiene por que poder
        # averiguar que placas hay en el sistema.
        def vehicle
          Garage::Vehicle.accessible_by(Current.organization).find(filters[:vehicle_id])
        end
      end
    end
  end
end
