require "rails_helper"

RSpec.describe Diagnostics::MonthlyHealthReportJob do
  let(:vehicle) { create(:vehicle) }

  it "genera el diagnostico del mes" do
    expect { described_class.perform_now(vehicle.id) }
      .to change(Diagnostics::HealthReport, :count).by(1)
  end

  it "no revienta si el vehiculo ya no existe" do
    id = vehicle.id
    vehicle.destroy

    expect { described_class.perform_now(id) }.not_to raise_error
  end
end
