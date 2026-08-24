require "rails_helper"

RSpec.describe Vehicle, "#part_types", type: :model do
  it "devuelve las piezas del catalogo que aplican a la moto" do
    chain = create(:part_type, :drive_chain)
    create(:part_type, :timing_belt)
    motorcycle = create(:vehicle, :motorcycle)

    expect(motorcycle.part_types).to contain_exactly(chain)
  end

  it "devuelve las piezas que aplican al auto" do
    create(:part_type, :drive_chain)
    timing_belt = create(:part_type, :timing_belt)
    car = create(:vehicle)

    expect(car.part_types).to contain_exactly(timing_belt)
  end
end
