module Diagnostics
  # Un campo del checklist.
  #
  # `value_type` y `unit` no son decoracion: son lo que obliga a capturar
  # milimetros y PSI en vez de "bueno/regular/malo". Medir el labrado en mm dos
  # meses seguidos da la velocidad de desgaste real de ese carro con ese
  # conductor, que es un modelo mejor que la curva generica de catalogo.
  class InspectionItem < ApplicationRecord
    # Las tres fases de la visita, en el orden en que se recorren. Los nombres
    # no son `off` e `idle` porque YAML los lee como booleanos, y el checklist se
    # edita en YAML.
    PHASES = {
      engine_off: "engine_off",
      engine_idle: "engine_idle",
      driving: "driving"
    }.freeze

    VALUE_TYPES = {
      numeric: "numeric",
      scale: "scale",
      boolean: "boolean",
      date: "date"
    }.freeze

    # Escala cerrada de 1 a 4: peor a mejor. Cerrada a proposito, para que dos
    # tecnicos distintos signifiquen lo mismo.
    SCALE_RANGE = (1..4).freeze

    belongs_to :template, class_name: "Diagnostics::InspectionTemplate"
    belongs_to :part_type, optional: true

    has_many :observations, foreign_key: :item_id, dependent: :destroy

    enum :phase, PHASES, validate: true, prefix: true
    enum :value_type, VALUE_TYPES, validate: true, prefix: :value

    validates :code, :label, :phase, :value_type, presence: true
    validates :code, uniqueness: { scope: :template_id }
    validates :unit, presence: true, if: :value_numeric?
    validates :maximum, comparison: { greater_than: :minimum }, if: -> { minimum && maximum }
  end
end
