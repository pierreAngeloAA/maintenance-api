# Carga los parametros de Weibull desde `db/seeds/reliability_profiles.yml`.
#
# Nunca pisa un perfil marcado como `user_data`: en cuanto un parametro se
# calcule con mantenimientos reales de usuarios, el seed deja de mandar sobre el.
module ReliabilityProfileCatalog
  CATALOG_PATH = Rails.root.join("db/seeds/reliability_profiles.yml")

  module_function

  def entries
    @entries ||= YAML.load_file(CATALOG_PATH).map { |entry| entry.transform_keys(&:to_s).freeze }.freeze
  end

  def load!
    part_types = PartType.where(code: entries.map { |entry| entry["part_code"] }).index_by(&:code)

    entries.each do |entry|
      part_type = part_types[entry["part_code"]]
      next if part_type.nil?

      profile = Reliability::ReliabilityProfile.find_or_initialize_by(
        part_type: part_type,
        vehicle_type: entry["vehicle_type"]
      )
      next unless profile.new_record? || profile.estimate?

      profile.update!(
        weibull_shape: entry["weibull_shape"],
        characteristic_life: entry["characteristic_life"],
        life_unit: entry["life_unit"],
        source: "engineering_estimate"
      )
    end
  end
end
