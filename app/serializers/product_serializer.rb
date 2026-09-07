module ProductSerializer
  module_function

  def call(product)
    {
      id: product.id,
      name: product.name,
      brand: product.brand,
      sku: product.sku,
      description: product.description,
      unitPriceCents: product.unit_price_cents,
      currency: product.currency,
      stockQuantity: product.stock_quantity,
      status: product.status,
      available: product.available?,
      # Anidados, y nulos cuando el almacen no declaro nada: "no tiene garantia"
      # se lee de una sola vez, sin revisar tres llaves sueltas.
      expectedLife: expected_life_payload(product),
      warranty: warranty_payload(product),
      # Sin compatibilidad declarada el producto sirve para todo (aceite,
      # liquido de frenos). Es una propiedad, no un dato faltante.
      universal: product.universal?,
      partType: product.part_type && PartTypeSerializer.call(product.part_type),
      organizationId: product.organization_id,
      createdAt: product.created_at
    }
  end

  def expected_life_payload(product)
    return nil unless product.expected_life?

    {
      usageValue: product.expected_life_usage_value,
      usageUnit: product.expected_life_usage_unit,
      months: product.expected_life_months
    }
  end

  def warranty_payload(product)
    return nil unless product.warranty?

    {
      usageValue: product.warranty_usage_value,
      usageUnit: product.warranty_usage_unit,
      months: product.warranty_months
    }
  end
end
