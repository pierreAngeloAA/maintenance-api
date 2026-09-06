# Quien esta actuando en esta peticion.
#
# El token dice *quien eres*; el header X-Organization-Id dice *en nombre de
# quien actuas ahora*. Si el rol viviera dentro del token, cada cambio de
# contexto obligaria a reemitirlo y habria tokens distintos conviviendo en el
# navegador.
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :organization, :membership

  # Sin organizacion activa, la persona actua sobre sus propios vehiculos.
  def client?
    organization.nil?
  end

  def workshop?
    organization&.workshop? || false
  end

  def store?
    organization&.store? || false
  end
end
