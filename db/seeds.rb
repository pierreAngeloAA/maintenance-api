# Los seeds son idempotentes: se pueden correr en cada deploy.
PartTypeCatalog.load!

puts "Catalogo de piezas: #{PartType.count} tipos de pieza cargados."
