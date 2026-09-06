FactoryBot.define do
  factory :product, class: "Catalog::Product" do
    organization { create(:organization, :store) }
    part_type
    sequence(:name) { |n| "Pastillas de freno #{n}" }
    brand { "Bosch" }
    sequence(:sku) { |n| "SKU-#{n}" }
    unit_price_cents { 12_000_000 }
    currency { "COP" }
    stock_quantity { 10 }
    status { "published" }

    trait :draft do
      status { "draft" }
    end

    trait :out_of_stock do
      stock_quantity { 0 }
    end
  end

  factory :fitment, class: "Catalog::Fitment" do
    product
    vehicle_type { "car" }
    make { "Renault" }
    model { "Logan" }
    year_from { 2015 }
    year_to { 2020 }
  end
end

FactoryBot.define do
  factory :order, class: "Orders::Order" do
    buyer { create(:user) }
    seller_organization { create(:organization, :store) }
    status { "pending" }
    placed_at { Time.current }
    subtotal_cents { 10_000 }
    total_cents { 10_000 }
  end
end
