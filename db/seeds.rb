# Los seeds son idempotentes: se pueden correr en cada deploy.
PartTypeCatalog.load!
ReliabilityProfileCatalog.load!

puts "Catalogo de piezas: #{PartType.count} tipos de pieza."
puts "Parametros de confiabilidad: #{Reliability::ReliabilityProfile.count} perfiles."
