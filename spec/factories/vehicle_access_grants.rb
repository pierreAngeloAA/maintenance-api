FactoryBot.define do
  factory :vehicle_access_grant, class: "Garage::VehicleAccessGrant" do
    vehicle
    organization
    granted_by { vehicle.user }
    access_level { "write" }
    granted_at { Time.current }

    trait :read_only do
      access_level { "read" }
    end

    trait :expired do
      granted_at { 2.days.ago }
      expires_at { 1.day.ago }
    end

    trait :revoked do
      revoked_at { Time.current }
    end
  end
end
