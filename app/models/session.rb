# Sesion de un usuario, identificada por un token bearer.
#
# El token en claro solo existe en memoria en el momento de crear la sesion: en
# la base de datos queda unicamente su digest. Asi, leer la tabla no alcanza para
# hacerse pasar por nadie.
class Session < ApplicationRecord
  belongs_to :user

  # Disponible solo en el objeto recien creado, para poder devolverselo al cliente.
  attr_reader :token

  before_create :generate_token

  def self.authenticate(token)
    return if token.blank?

    find_by(token_digest: digest(token))
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  private

  def generate_token
    @token = SecureRandom.urlsafe_base64(32)
    self.token_digest = self.class.digest(@token)
  end
end
