# El flujo de trabajo del marketplace: el cliente pide, se ofrece a los talleres
# cercanos, uno lo toma y va.
#
# Ojo con el nombre: este modulo son los MODELOS del dominio de servicios y vive
# en app/models/services/. No confundir con app/services/, que es la carpeta de
# objetos de logica de negocio (Nhtsa::, Reliability::, Runt::...).
module Services
  def self.table_name_prefix
    "services_"
  end
end
