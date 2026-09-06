# Carga los checklists desde `db/seeds/inspection_templates.yml`.
#
# Igual que el catalogo de piezas: el contenido vive en datos y no en codigo, de
# modo que cambiar el checklist sea editar YAML. Lo que cambia respecto a las
# piezas es que aca **no se edita en sitio**: una plantilla publicada no se
# toca, se publica la version siguiente, porque las mediciones viejas tienen que
# seguir siendo comparables.
module InspectionTemplateCatalog
  CATALOG_PATH = Rails.root.join("db/seeds/inspection_templates.yml")

  module_function

  def entries
    @entries ||= YAML.load_file(CATALOG_PATH).map(&:freeze).freeze
  end

  # Idempotente, pero solo crea: si la version ya existe, se deja como esta.
  def load!
    entries.each { |entry| load_template(entry) }
  end

  def load_template(entry)
    template = Diagnostics::InspectionTemplate.find_by(
      code: entry["code"], version: entry["version"]
    )
    return template if template

    # Todo o nada: una plantilla sin campos es peor que no tenerla, porque el
    # tecnico abriria una inspeccion vacia sin entender por que.
    Diagnostics::InspectionTemplate.transaction do
      created = Diagnostics::InspectionTemplate.create!(
        code: entry["code"], version: entry["version"],
        vehicle_type: entry["vehicle_type"], published_at: Time.current
      )
      create_items(created, entry["items"])
      created
    end
  end

  def create_items(template, items)
    part_types = PartType.pluck(:code, :id).to_h

    items.each_with_index do |item, index|
      template.items.create!(
        code: item["code"], label: item["label"], phase: item["phase"],
        value_type: item["value_type"], unit: item["unit"],
        minimum: item["minimum"], maximum: item["maximum"],
        part_type_id: part_types[item["part_code"]], position: index
      )
    end
  end
end
