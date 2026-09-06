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
      # Sin compatibilidad declarada el producto sirve para todo (aceite,
      # liquido de frenos). Es una propiedad, no un dato faltante.
      universal: product.universal?,
      partType: product.part_type && PartTypeSerializer.call(product.part_type),
      organizationId: product.organization_id,
      createdAt: product.created_at
    }
  end
end
