# La visita de 30 minutos y lo que sale de ella.
#
# Es el activo mas valioso del producto: es lo unico que mide el estado fisico
# real de un vehiculo concreto, y es lo que con el tiempo permite reemplazar los
# parametros de catalogo (`source: engineering_estimate`) por parametros medidos
# de la flota propia.
module Diagnostics
  def self.table_name_prefix
    "diagnostics_"
  end
end
