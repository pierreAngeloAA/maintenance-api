FactoryBot.define do
  factory :vehicle do
    vehicle_type { "car" }
    make { "Renault" }
    model { "Logan" }
    model_year { 2019 }
    sequence(:vin) { |n| format("1HGBH41JXMN%06d", n) }
    sequence(:plate) { |n| format("ABC%03d", n % 1000) }
    usage_value { 45_000 }
    usage_unit { "km" }
    city { "Bogota" }

    trait :motorcycle do
      vehicle_type { "motorcycle" }
      make { "AKT" }
      model { "NKD 125" }
      model_year { 2021 }
      # Las motos colombianas no estan en NHTSA: se registran sin VIN.
      vin { nil }
      sequence(:plate) { |n| format("XYZ%02dA", n % 100) }
      usage_value { 12_000 }
      specs { { "displacement_cc" => 125 } }
    end
  end
end
