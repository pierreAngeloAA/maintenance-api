# Permite que el frontend Angular (maintenance-web) consuma esta API.
#
# El frontend son TRES apps, y en desarrollo cada una corre en su propio puerto:
# cliente 4200, taller 4201, almacen 4202. Si el origen de alguna no esta
# permitido, el navegador descarta la respuesta aunque el API haya contestado
# 200, y la pantalla muestra un error de carga que no explica nada.
#
# En produccion las tres se sirven bajo un mismo dominio, asi que ahi basta con
# un solo origen en CORS_ORIGINS.
DEFAULT_DEV_ORIGINS = %w[
  http://localhost:4200
  http://localhost:4201
  http://localhost:4202
].join(",").freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGINS", DEFAULT_DEV_ORIGINS).split(",").map(&:strip)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "Authorization" ]
  end
end
