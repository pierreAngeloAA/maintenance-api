module FitmentSerializer
  module_function

  def call(fitment)
    {
      id: fitment.id,
      productId: fitment.product_id,
      vehicleType: fitment.vehicle_type,
      # Nulo significa "cualquiera": sirve para toda la marca o toda la linea.
      make: fitment.make,
      model: fitment.model,
      yearFrom: fitment.year_from,
      yearTo: fitment.year_to
    }
  end
end
