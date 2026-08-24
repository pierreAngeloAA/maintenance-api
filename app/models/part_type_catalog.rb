# Carga el catalogo base de tipos de pieza desde `db/seeds/part_types.yml`.
#
# El catalogo vive en un archivo de datos y no en codigo para que agregar piezas
# (o una clase nueva de vehiculo) sea editar YAML, no escribir Ruby.
module PartTypeCatalog
  CATALOG_PATH = Rails.root.join("db/seeds/part_types.yml")

  module_function

  def entries
    @entries ||= YAML.load_file(CATALOG_PATH).map(&:freeze).freeze
  end

  # Idempotente: se puede correr en cada deploy sin duplicar ni perder piezas.
  def load!
    entries.each do |entry|
      PartType.find_or_initialize_by(code: entry["code"]).update!(entry)
    end
  end
end
