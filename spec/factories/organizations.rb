FactoryBot.define do
  factory :organization, class: "Identity::Organization" do
    kind { "workshop" }
    sequence(:name) { |n| "Taller #{n}" }
    city { "Bogota" }
    status { "active" }

    trait :store do
      kind { "store" }
      sequence(:name) { |n| "Repuestos #{n}" }
    end

    trait :pending do
      status { "pending" }
    end

    trait :suspended do
      status { "suspended" }
    end
  end
end
