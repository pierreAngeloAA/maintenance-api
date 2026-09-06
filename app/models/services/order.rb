module Services
  # El trabajo aceptado. Una solicitud se convierte en una sola orden, y eso lo
  # garantiza un indice unico: es lo que impide que dos tecnicos tomen el mismo
  # servicio sin depender de que el codigo se acuerde de revisarlo.
  class Order < ApplicationRecord
    STATUSES = {
      assigned: "assigned",
      en_route: "en_route",
      in_progress: "in_progress",
      completed: "completed",
      canceled: "canceled"
    }.freeze

    # Hacia donde puede avanzar cada estado. Lo que no este aca, no pasa.
    TRANSITIONS = {
      "assigned" => %w[en_route in_progress canceled],
      "en_route" => %w[in_progress canceled],
      "in_progress" => %w[completed canceled],
      "completed" => [],
      "canceled" => []
    }.freeze

    FINAL_STATUSES = %w[completed canceled].freeze

    belongs_to :request
    belongs_to :organization, class_name: "Identity::Organization"
    belongs_to :technician_user, class_name: "User"

    has_one :vehicle, through: :request

    enum :status, STATUSES, validate: true, prefix: :status

    validates :status, presence: true
    validates :total_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    def can_transition_to?(next_status)
      TRANSITIONS.fetch(status, []).include?(next_status.to_s)
    end

    def final?
      FINAL_STATUSES.include?(status)
    end
  end
end
