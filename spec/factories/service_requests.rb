FactoryBot.define do
  factory :service_request, class: "Services::Request" do
    vehicle
    requested_by_user { vehicle.user }
    kind { "monthly_inspection" }
    status { "pending" }
    address { "Calle 100 #15-20" }
    latitude { 4.6533 }
    longitude { -74.0836 }
  end

  factory :service_offer, class: "Services::Offer" do
    association :request, factory: :service_request
    organization
    status { "offered" }
    expires_at { 1.day.from_now }

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
