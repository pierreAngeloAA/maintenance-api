# Quien esta actuando en esta peticion.
#
# El token dice *quien eres*; el header X-Organization-Id dice *en nombre de
# quien actuas ahora*. Si el rol viviera dentro del token, cada cambio de
# contexto obligaria a reemitirlo y habria tokens distintos conviviendo en el
# navegador.
#
# Los predicados por clase de organizacion (workshop?, store?) entran con la
# capa de politicas, que es quien los va a necesitar.
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :organization, :membership

  # Sin organizacion activa, la persona actua sobre sus propios vehiculos.
  def client?
    organization.nil?
  end
end
