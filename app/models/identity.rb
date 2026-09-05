# Quien es quien: personas, organizaciones y la relacion entre ambas.
#
# El prefijo de tabla hace que la frontera del modulo se vea tambien en la base
# de datos. Las tablas anteriores a los modulos (vehicles, part_types...) se
# quedaron sin prefijo a proposito: renombrarlas no compraba nada.
module Identity
  def self.table_name_prefix
    "identity_"
  end
end
