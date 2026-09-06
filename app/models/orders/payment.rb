module Orders
  # El registro del pago, no el pago.
  #
  # Cada almacen aliado es el comercio ante la pasarela: el dinero va directo
  # del cliente al almacen y la plataforma nunca lo toca. Por eso esta tabla
  # guarda una referencia y un estado, y no un saldo.
  class Payment < ApplicationRecord
    STATUSES = {
      pending: "pending",
      approved: "approved",
      declined: "declined",
      refunded: "refunded"
    }.freeze

    belongs_to :order

    enum :status, STATUSES, validate: true, prefix: true

    validates :gateway, presence: true
    validates :amount_cents,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :gateway_ref, uniqueness: { scope: :gateway }, allow_nil: true
  end
end
