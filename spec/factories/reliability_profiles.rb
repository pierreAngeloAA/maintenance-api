FactoryBot.define do
  factory :reliability_profile, class: "Reliability::ReliabilityProfile" do
    part_type
    vehicle_type { "car" }
    weibull_shape { 2.5 }
    characteristic_life { 30_000 }
    life_unit { "km" }
    source { "engineering_estimate" }
  end
end
