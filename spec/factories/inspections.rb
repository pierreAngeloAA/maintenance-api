FactoryBot.define do
  factory :inspection_template, class: "Diagnostics::InspectionTemplate" do
    sequence(:code) { |n| "checklist_#{n}" }
    version { 1 }
    vehicle_type { "car" }
    published_at { Time.current }

    trait :draft do
      published_at { nil }
    end
  end

  factory :inspection_item, class: "Diagnostics::InspectionItem" do
    association :template, factory: :inspection_template
    sequence(:code) { |n| "item_#{n}" }
    label { "Labrado llanta delantera izquierda" }
    phase { "engine_off" }
    value_type { "numeric" }
    unit { "mm" }
    minimum { 0 }
    maximum { 20 }

    trait :scale do
      value_type { "scale" }
      unit { nil }
      minimum { nil }
      maximum { nil }
    end

    trait :boolean do
      value_type { "boolean" }
      unit { nil }
      minimum { nil }
      maximum { nil }
    end
  end

  factory :inspection, class: "Diagnostics::Inspection" do
    vehicle
    association :template, factory: :inspection_template
    technician_user { create(:user) }
    organization
    status { "in_progress" }
    usage_value { 45_000 }
    started_at { 20.minutes.ago }

    # Una visita cerrada trae siempre su evidencia: foto, ubicacion y al menos
    # una medicion. Sin eso el modelo no la deja cerrar, y con razon.
    trait :completed do
      status { "completed" }
      performed_at { Time.current }
      latitude { 4.6533 }
      longitude { -74.0836 }
      duration_seconds { 1_800 }

      after(:build) do |inspection|
        inspection.photos.attach(
          io: StringIO.new("foto"), filename: "llanta.jpg", content_type: "image/jpeg"
        )
      end

      after(:stub) { |inspection| inspection }

      before(:create) do |inspection|
        inspection.observations.build(
          item: create(:inspection_item, template: inspection.template),
          numeric_value: 4.5, severity: "ok"
        )
      end
    end
  end
end

FactoryBot.define do
  factory :observation, class: "Diagnostics::Observation" do
    inspection
    item { create(:inspection_item, template: inspection.template) }
    numeric_value { 4.5 }
    severity { "ok" }
  end
end
