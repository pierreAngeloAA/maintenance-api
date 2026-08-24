Rails.application.routes.draw do
  # Health check usado por Render.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Registro, inicio y cierre de sesion.
      resources :users, only: :create
      resource :session, only: [ :create, :destroy ], path: "sessions", controller: "sessions"
      get "me", to: "me#show"

      resources :vehicles, only: [ :index, :show, :create ] do
        # Recalls de seguridad reportados por NHTSA para ese vehiculo.
        resource :recalls, only: :show, controller: "recalls"

        # Historial de mantenimientos y riesgo de falla por pieza.
        resources :maintenance_records, only: [ :index, :create ]
        resource :risks, only: :show, controller: "risks"
      end

      # Autocompletado del formulario. Responde 200 aunque NHTSA no conozca el
      # vehiculo: no encontrarlo no es un error.
      get "vin_lookups/:vin", to: "vin_lookups#show", as: :vin_lookup
    end
  end
end
