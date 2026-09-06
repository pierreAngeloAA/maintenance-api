module OrderSerializer
  module_function

  def call(order)
    {
      id: order.id,
      status: order.status,
      subtotalCents: order.subtotal_cents,
      totalCents: order.total_cents,
      currency: order.currency,
      address: order.address,
      placedAt: order.placed_at,
      sellerOrganization: {
        id: order.seller_organization_id,
        name: order.seller_organization.name
      },
      # Quien compro: una persona o un taller. La app decide como mostrarlo.
      buyerType: order.buyer_type,
      buyerId: order.buyer_id,
      items: order.items.map { |item| item_payload(item) },
      # La referencia del pago, cuando el almacen la registro. La plataforma no
      # mueve plata: solo deja constancia para conciliar.
      payments: order.payments.map { |payment| payment_payload(payment) }
    }
  end

  def payment_payload(payment)
    {
      id: payment.id,
      gateway: payment.gateway,
      gatewayRef: payment.gateway_ref,
      status: payment.status,
      amountCents: payment.amount_cents
    }
  end

  def item_payload(item)
    {
      id: item.id,
      # Copiados al comprar: si el almacen cambia el producto despues, la orden
      # sigue diciendo lo que se vendio.
      productName: item.product_name,
      productBrand: item.product_brand,
      productSku: item.product_sku,
      productId: item.product_id,
      quantity: item.quantity,
      unitPriceCents: item.unit_price_cents,
      totalCents: item.total_cents
    }
  end
end
