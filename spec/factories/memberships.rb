FactoryBot.define do
  factory :membership, class: "Identity::Membership" do
    user
    organization
    role { "owner" }
    accepted_at { Time.current }

    # Invitado pero sin aceptar todavia: no da permisos.
    trait :invited do
      role { "technician" }
      invited_at { Time.current }
      accepted_at { nil }
    end
  end
end
