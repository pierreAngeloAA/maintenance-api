FactoryBot.define do
  factory :part_type do
    sequence(:code) { |n| "part_type_#{n}" }
    name { "Aceite de motor" }
    category { "engine" }
    applicable_vehicle_types { %w[car] }

    trait :drive_chain do
      code { "drive_chain" }
      name { "Cadena de transmision" }
      category { "transmission" }
      applicable_vehicle_types { %w[motorcycle] }
    end

    trait :timing_belt do
      code { "timing_belt" }
      name { "Correa de repartición" }
      category { "engine" }
      applicable_vehicle_types { %w[car] }
    end
  end
end
