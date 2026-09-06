module Orders
  # Una compra a un almacen.
  class Order < ApplicationRecord
    STATUSES = {
      pending: "pending",
      paid: "paid",
      shipped: "shipped",
      delivered: "delivered",
      canceled: "canceled"
    }.freeze

    # Hacia donde puede avanzar cada estado. Lo que no este aca, no pasa.
    TRANSITIONS = {
      "pending" => %w[paid canceled],
      "paid" => %w[shipped canceled],
      "shipped" => %w[delivered],
      "delivered" => [],
      "canceled" => []
    }.freeze

    belongs_to :buyer, polymorphic: true
    belongs_to :seller_organization, class_name: "Identity::Organization"

    has_many :items, dependent: :destroy
    has_many :payments, dependent: :destroy

    enum :status, STATUSES, validate: true, prefix: true

    validates :status, :placed_at, presence: true
    validates :subtotal_cents, :total_cents,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validate :seller_is_a_store

    scope :recent_first, -> { order(placed_at: :desc) }

    def can_transition_to?(next_status)
      TRANSITIONS.fetch(status, []).include?(next_status.to_s)
    end

    private

    def seller_is_a_store
      return if seller_organization.nil? || seller_organization.store?

      errors.add(:seller_organization, :inclusion)
    end
  end
end
