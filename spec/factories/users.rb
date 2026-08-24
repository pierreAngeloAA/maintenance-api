FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "pierre#{n}@example.com" }
    password { "unaClaveSegura1" }
    name { "Pierre" }
  end
end
