module Services
  # La solicitud puesta frente a un taller cercano. La oferta es del taller; la
  # toma una persona concreta, que queda anotada al aceptar.
  class Offer < ApplicationRecord
    STATUSES = {
      offered: "offered",
      accepted: "accepted",
      rejected: "rejected",
      expired: "expired"
    }.freeze

    belongs_to :request
    belongs_to :organization, class_name: "Identity::Organization"
    belongs_to :technician_user, class_name: "User", optional: true

    enum :status, STATUSES, validate: true, prefix: :status

    validates :status, presence: true
    validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    scope :open, -> {
      where(status: "offered").where("expires_at IS NULL OR expires_at > ?", Time.current)
    }

    def open?
      status_offered? && (expires_at.nil? || expires_at.future?)
    end
  end
end
