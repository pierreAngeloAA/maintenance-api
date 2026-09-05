module Identity
  # Un taller o un almacen.
  #
  # Un tecnico independiente tambien es una Organization: un taller de una sola
  # persona. Exigir una empresa detras dejaria por fuera a buena parte del
  # mercado, y que *todos* actuen en nombre de una organizacion evita que el
  # permiso sobre el vehiculo, la orden y la factura necesiten un actor
  # polimorfico con dos ramas por consulta.
  class Organization < ApplicationRecord
    KINDS = { store: "store", workshop: "workshop" }.freeze

    # `pending` hasta que se verifique: se va a mandar gente a la casa de un
    # cliente, asi que la verificacion es parte de la confianza del producto.
    STATUSES = { pending: "pending", active: "active", suspended: "suspended" }.freeze

    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    has_many :vehicle_access_grants, class_name: "Garage::VehicleAccessGrant", dependent: :destroy

    # `scopes: false` porque el valor "store" generaria una clase de scope
    # Organization.store, que Active Record ya define (ActiveRecord::Store).
    # Los predicados (workshop?, store?) se conservan, que es lo que se usa.
    enum :kind, KINDS, validate: true, scopes: false
    enum :status, STATUSES, validate: true

    normalizes :nit, with: ->(nit) { nit.gsub(/[\s.-]/, "") }

    validates :name, presence: true
    validates :kind, :status, presence: true
    validates :nit, uniqueness: true, allow_nil: true
  end
end
