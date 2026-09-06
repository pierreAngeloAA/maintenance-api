module Services
  # Lo que pide el cliente: una revision mensual, una reparacion o una cotizacion.
  class Request < ApplicationRecord
    KINDS = {
      monthly_inspection: "monthly_inspection",
      repair: "repair",
      quote: "quote"
    }.freeze

    STATUSES = {
      pending: "pending",
      assigned: "assigned",
      completed: "completed",
      canceled: "canceled"
    }.freeze

    belongs_to :vehicle, class_name: "Garage::Vehicle"
    belongs_to :requested_by_user, class_name: "User"

    has_many :offers, dependent: :destroy
    has_one :order, dependent: :destroy

    enum :kind, KINDS, validate: true
    enum :status, STATUSES, validate: true, prefix: :status

    validates :kind, :status, presence: true
    validate :scheduled_for_is_not_in_the_past, on: :create

    # Solo se puede tomar lo que sigue pendiente.
    scope :open, -> { where(status: "pending") }

    def open?
      status_pending?
    end

    private

    def scheduled_for_is_not_in_the_past
      return if scheduled_for.blank? || scheduled_for >= Time.current

      errors.add(:scheduled_for, :greater_than_or_equal_to, count: Time.current)
    end
  end
end
