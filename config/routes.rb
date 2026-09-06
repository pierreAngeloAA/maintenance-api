Rails.application.routes.draw do
  # Health check usado por Render.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Registro, inicio y cierre de sesion. No cuelgan de ninguna audiencia:
      # la identidad es una sola y el rol se resuelve despues.
      resources :users, only: :create
      resource :session, only: [ :create, :destroy ], path: "sessions", controller: "sessions"
      get "me", to: "me#show"

      # Alta de talleres y almacenes: un cliente se vuelve tambien taller o
      # almacen sin crear otra cuenta.
      resources :organizations, only: [ :create, :update ]

      # Autocompletado del formulario, compartido por las tres apps. Responde 200
      # aunque NHTSA no conozca el vehiculo: no encontrarlo no es un error.
      get "vin_lookups/:vin", to: "vin_lookups#show", as: :vin_lookup

      # App del cliente: sus vehiculos y todo lo que cuelga de ellos.
      namespace :client do
        resources :vehicles, only: [ :index, :show, :create ] do
          # Recalls de seguridad reportados por NHTSA para ese vehiculo.
          resource :recalls, only: :show, controller: "recalls"

          # Historial de mantenimientos y riesgo de falla por pieza.
          resources :maintenance_records, only: [ :index, :create ]
          resource :risks, only: :show, controller: "risks"

          # Quien tiene acceso a este vehiculo, y como quitarselo.
          resources :access_grants, only: [ :index, :create, :destroy ]

          # El diagnostico del mes y el historial de los anteriores.
          resource :health_report, only: :show
          resources :health_reports, only: :index

          # Repuestos que sirven para este vehiculo.
          resources :products, only: :index
        end

        # Lo que el cliente pide para sus vehiculos.
        resources :service_requests, only: [ :index, :create, :destroy ]

        # Compras de repuestos.
        resources :orders, only: [ :index, :show, :create ]
      end

      # App del taller: solo los vehiculos con permiso vigente del dueno.
      namespace :workshop do
        resources :vehicles, only: [ :index, :show ] do
          resources :maintenance_records, only: [ :index, :create ]
        end

        # Tomar servicios y llevarlos hasta el cierre.
        resources :service_offers, only: [ :index, :update, :destroy ]
        resources :service_orders, only: [ :index, :update ]

        # El taller compra repuestos para sus trabajos.
        resources :orders, only: [ :index, :create ]

        # La visita de 30 minutos. Las mediciones se guardan una por una a
        # medida que el tecnico avanza, no todas al cerrar.
        resources :inspections, only: [ :show, :create, :update ] do
          resources :observations, only: :create
        end
      end

      # App del almacen: su catalogo y sus ventas.
      namespace :store do
        resources :products, only: [ :index, :create, :update ] do
          # Para que vehiculos sirve cada producto.
          resources :fitments, only: [ :index, :create, :destroy ]
        end

        # Sus ventas.
        resources :orders, only: [ :index, :update ]
      end
    end
  end
end
