# Los seeds son idempotentes: se pueden correr en cada deploy.
PartTypeCatalog.load!
ReliabilityProfileCatalog.load!
InspectionTemplateCatalog.load!

puts "Catalogo de piezas: #{PartType.count} tipos de pieza."
puts "Parametros de confiabilidad: #{Reliability::ReliabilityProfile.count} perfiles."
puts "Checklists: #{Diagnostics::InspectionTemplate.count} plantillas, #{Diagnostics::InspectionItem.count} campos."
