FactoryBot.define do
  factory :maintenance_record, class: "Garage::MaintenanceRecord" do
    vehicle
    part_type { create(:part_type, applicable_vehicle_types: [ vehicle.vehicle_type ]) }
    performed_on { Date.current - 30 }
    usage_at_service { 10_000 }
    part_brand { "DID" }
    currency { "COP" }
  end
end
