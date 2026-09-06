module Services
  # Pone una solicitud frente a los talleres cercanos.
  #
  # Las ofertas se materializan al crear la solicitud, en vez de calcularse al
  # leer, para que "quien la vio y quien la rechazo" quede registrado y para que
  # aceptar sea una operacion sobre una fila concreta.
  class RequestBroadcast
    DEFAULT_TTL = 24.hours

    def initialize(request, radius_km: NearbyWorkshops::DEFAULT_RADIUS_KM, ttl: DEFAULT_TTL)
      @request = request
      @radius_km = radius_km
      @ttl = ttl
    end

    def call
      workshops.map do |workshop|
        request.offers.create!(organization: workshop, expires_at: ttl.from_now)
      end
    end

    private

    attr_reader :request, :radius_km, :ttl

    def workshops
      NearbyWorkshops.call(
        latitude: request.latitude,
        longitude: request.longitude,
        radius_km: radius_km
      )
    end
  end
end
