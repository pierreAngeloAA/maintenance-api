require "rails_helper"

RSpec.describe Orders::Placement do
  let(:store) { create(:organization, :store) }
  let(:buyer) { create(:user) }
  let(:product) do
    create(:product, organization: store, unit_price_cents: 10_000, stock_quantity: 5,
      name: "Pastillas", brand: "Bosch", sku: "BP-1")
  end

  def place(lines, who: buyer)
    described_class.new(buyer: who, lines: lines).call
  end

  it "crea la orden con su linea" do
    result = place([ { product_id: product.id, quantity: 2 } ])

    expect(result).to be_success
    expect(result.order.items.first).to have_attributes(quantity: 2, unit_price_cents: 10_000)
  end

  it "suma el total" do
    result = place([ { product_id: product.id, quantity: 3 } ])

    expect(result.order.total_cents).to eq(30_000)
  end

  # El error clasico: referenciar el precio vivo del producto.
  it "congela el precio: si el almacen lo sube despues, la orden no cambia" do
    order = place([ { product_id: product.id, quantity: 1 } ]).order

    product.update!(unit_price_cents: 99_000)

    expect(order.reload.items.first.unit_price_cents).to eq(10_000)
    expect(order.total_cents).to eq(10_000)
  end

  it "copia nombre, marca y SKU en vez de referenciarlos" do
    order = place([ { product_id: product.id, quantity: 1 } ]).order

    product.update!(name: "Otro nombre", brand: "Otra marca")

    expect(order.reload.items.first).to have_attributes(
      product_name: "Pastillas", product_brand: "Bosch", product_sku: "BP-1"
    )
  end

  it "descuenta el stock" do
    expect { place([ { product_id: product.id, quantity: 2 } ]) }
      .to change { product.reload.stock_quantity }.from(5).to(3)
  end

  it "no deja pedir mas de lo que hay" do
    result = place([ { product_id: product.id, quantity: 99 } ])

    expect(result.error).to eq(:out_of_stock)
    expect(Orders::Order.count).to eq(0)
    expect(product.reload.stock_quantity).to eq(5)
  end

  it "no deja comprar un borrador ni algo sin stock" do
    expect(place([ { product_id: create(:product, :draft).id, quantity: 1 } ]).error)
      .to eq(:product_not_available)
    expect(place([ { product_id: create(:product, :out_of_stock).id, quantity: 1 } ]).error)
      .to eq(:product_not_available)
  end

  it "rechaza un carrito vacio" do
    expect(place([]).error).to eq(:empty_cart)
  end

  # Mezclar vendedores complicaria el despacho y el pago sin darle nada al usuario.
  it "no deja mezclar productos de dos almacenes en una orden" do
    otro = create(:product)

    result = place([ { product_id: product.id, quantity: 1 },
                     { product_id: otro.id, quantity: 1 } ])

    expect(result.error).to eq(:multiple_sellers)
  end

  # Un taller comprando y un cliente comprando son la misma operacion.
  it "un taller puede ser el comprador" do
    workshop = create(:organization)

    result = place([ { product_id: product.id, quantity: 1 } ], who: workshop)

    expect(result.order.buyer).to eq(workshop)
  end

  # Si dos personas compran la ultima unidad, una gana.
  it "si algo falla a mitad, no queda ni orden ni stock descontado" do
    ultimo = create(:product, organization: store, stock_quantity: 1)

    place([ { product_id: ultimo.id, quantity: 1 } ])
    segundo = place([ { product_id: ultimo.id, quantity: 1 } ])

    expect(segundo.error).to eq(:product_not_available)
    expect(ultimo.reload.stock_quantity).to eq(0)
  end

  # Un almacen suspendido, un producto sin marca: cualquier cosa que invalide un
  # registro dentro de la transaccion deja la orden sin crearse.
  it "si un registro no pasa validacion, no queda nada a medias" do
    allow_any_instance_of(Orders::Item).to receive(:save!)
      .and_raise(ActiveRecord::RecordInvalid.new(Orders::Item.new))

    result = place([ { product_id: product.id, quantity: 1 } ])

    expect(result.error).to eq(:invalid)
    expect(Orders::Order.count).to eq(0)
  end
end
