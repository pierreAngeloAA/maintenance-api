module Diagnostics
  # Una visita concreta.
  class Inspection < ApplicationRecord
    STATUSES = { in_progress: "in_progress", completed: "completed" }.freeze

    # Se remunera, aunque sea en leads: tiene que poder auditarse que ocurrio.
    MINIMUM_PHOTOS = 1

    belongs_to :vehicle, class_name: "Garage::Vehicle"
    belongs_to :template, class_name: "Diagnostics::InspectionTemplate"
    belongs_to :technician_user, class_name: "User"
    belongs_to :organization, class_name: "Identity::Organization"
    belongs_to :service_order, class_name: "Services::Order", optional: true

    has_many :observations, dependent: :destroy
    has_many_attached :photos

    enum :status, STATUSES, validate: true, prefix: :status

    validates :status, :started_at, presence: true
    # Sin el kilometraje del momento, una medicion en mm no vale nada.
    validates :usage_value, presence: true, numericality: { greater_than_or_equal_to: 0 }

    validate :closing_requires_evidence, if: :status_completed?

    scope :completed, -> { where(status: "completed") }

    def self.latest_for(vehicle)
      completed.where(vehicle: vehicle).order(performed_at: :desc).first
    end

    private

    def closing_requires_evidence
      errors.add(:performed_at, :blank) if performed_at.blank?
      errors.add(:latitude, :blank) if latitude.blank? || longitude.blank?
      errors.add(:photos, :too_short, count: MINIMUM_PHOTOS) if photos.count < MINIMUM_PHOTOS
      errors.add(:observations, :blank) if observations.empty?
    end
  end
end
