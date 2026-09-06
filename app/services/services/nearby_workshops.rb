module Services
  # Los talleres a los que se les ofrece una solicitud.
  #
  # Distancia con Haversine en SQL, sin extensiones: `cube`/`earthdistance` y
  # PostGIS resuelven lo mismo pero hay que habilitarlos en el servidor, y a este
  # volumen no compran nada. Cuando el catalogo de talleres crezca lo suficiente
  # como para necesitar un indice espacial, se cambia aca y en ningun otro lado.
  module NearbyWorkshops
    DEFAULT_RADIUS_KM = 15
    EARTH_RADIUS_KM = 6371

    module_function

    def call(latitude:, longitude:, radius_km: DEFAULT_RADIUS_KM)
      return Identity::Organization.none if latitude.blank? || longitude.blank?

      Identity::Organization
        .where(kind: "workshop", status: "active")
        .where.not(latitude: nil, longitude: nil)
        .where(distance_sql, latitude, longitude, latitude, radius_km)
    end

    def distance_sql
      <<~SQL.squish
        #{EARTH_RADIUS_KM} * acos(
          least(1.0,
            cos(radians(?)) * cos(radians(latitude)) *
            cos(radians(longitude) - radians(?)) +
            sin(radians(?)) * sin(radians(latitude))
          )
        ) <= ?
      SQL
    end
  end
end
