require "rails_helper"

# La consulta al RUNT tarda 30-90 segundos la primera vez que se pregunta por
# una placa: va en background, nunca dentro del request.
RSpec.describe Garage::Vehicle, "consulta al RUNT", type: :model do
  include ActiveJob::TestHelper

  it "encola la consulta al registrar un vehiculo con placa" do
    expect { create(:vehicle, plate: "ABC123") }
      .to have_enqueued_job(Runt::VehicleLookupJob)
  end

  it "no encola nada si el vehiculo no tiene placa" do
    expect { create(:vehicle, plate: nil) }
      .not_to have_enqueued_job(Runt::VehicleLookupJob)
  end

  it "no vuelve a encolar al actualizar otros datos" do
    vehicle = create(:vehicle, plate: "ABC123")

    expect { vehicle.update!(usage_value: 60_000) }
      .not_to have_enqueued_job(Runt::VehicleLookupJob)
  end
end
