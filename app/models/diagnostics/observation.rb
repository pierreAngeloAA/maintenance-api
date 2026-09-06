module Diagnostics
  # Lo que el tecnico midio en un campo del checklist.
  #
  # No es un mantenimiento: un mantenimiento dice "se cambio la pieza" y
  # reinicia el reloj; una observacion dice "se vio que estaba asi" y no
  # reinicia nada. En confiabilidad, saber que una pieza seguia viva a los
  # 45.000 km es un dato censado por la derecha, y es lo que permite recalibrar
  # las curvas con datos reales.
  class Observation < ApplicationRecord
    SEVERITIES = {
      ok: "ok",
      watch: "watch",
      replace_soon: "replace_soon",
      replace_now: "replace_now"
    }.freeze

    belongs_to :inspection
    belongs_to :item, class_name: "Diagnostics::InspectionItem"
    belongs_to :part_type, optional: true

    # Opcional a proposito: la medicion es el hecho y la severidad es una
    # interpretacion. Exigirla duplicaria los toques por campo, y el tecnico
    # esta de pie con el celular en una mano.
    enum :severity, SEVERITIES, validate: { allow_nil: true }, prefix: true

    validates :item_id, uniqueness: { scope: :inspection_id }
    validate :value_matches_item_type
    validate :numeric_value_within_item_range

    before_validation :inherit_part_type, on: :create

    def value
      case item&.value_type
      when "numeric" then numeric_value
      when "scale" then scale_value
      when "boolean" then boolean_value
      when "date" then date_value
      end
    end

    private

    def inherit_part_type
      self.part_type ||= item&.part_type
    end

    def value_matches_item_type
      return if item.nil?
      return if value_present?

      errors.add(value_attribute, :blank)
    end

    def value_present?
      case item.value_type
      when "numeric" then numeric_value.present?
      when "scale" then InspectionItem::SCALE_RANGE.cover?(scale_value)
      when "boolean" then !boolean_value.nil?
      when "date" then date_value.present?
      end
    end

    def value_attribute
      { "numeric" => :numeric_value, "scale" => :scale_value,
        "boolean" => :boolean_value, "date" => :date_value }.fetch(item.value_type)
    end

    def numeric_value_within_item_range
      return if item.nil? || numeric_value.blank?
      return if within?(item.minimum, item.maximum)

      errors.add(:numeric_value, :inclusion)
    end

    def within?(minimum, maximum)
      (minimum.blank? || numeric_value >= minimum) && (maximum.blank? || numeric_value <= maximum)
    end
  end
end
