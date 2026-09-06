require "rails_helper"

RSpec.describe Diagnostics::Inspection, type: :model do
  let(:inspection) { create(:inspection) }

  def photo
    Rack::Test::UploadedFile.new(
      StringIO.new("foto"), "image/jpeg", original_filename: "llanta.jpg"
    )
  end

  it "es valida con los atributos de la factory" do
    expect(build(:inspection)).to be_valid
  end

  # Sin el kilometraje del momento, una medicion de 4,5 mm no significa nada:
  # es la mitad del dato que hace valiosa la visita.
  it "exige el kilometraje del momento" do
    expect(build(:inspection, usage_value: nil)).not_to be_valid
  end

  describe "cerrar la visita" do
    def close(**overrides)
      attributes = { status: "completed", performed_at: Time.current,
                     latitude: 4.6533, longitude: -74.0836 }.merge(overrides)
      inspection.photos.attach(io: StringIO.new("foto"), filename: "l.jpg",
        content_type: "image/jpeg") unless overrides[:skip_photo]
      create(:observation, inspection: inspection) unless overrides[:skip_observations]
      inspection.assign_attributes(attributes.except(:skip_photo, :skip_observations))
      inspection
    end

    it "se cierra con evidencia completa" do
      expect(close).to be_valid
    end

    # Se remunera, aunque sea en leads: tiene que poder auditarse que ocurrio.
    it "no se cierra sin foto" do
      expect(close(skip_photo: true)).not_to be_valid
    end

    it "no se cierra sin ubicacion" do
      expect(close(latitude: nil, longitude: nil)).not_to be_valid
    end

    it "no se cierra sin ninguna medicion" do
      expect(close(skip_observations: true)).not_to be_valid
    end

    it "no se cierra sin la fecha de la visita" do
      expect(close(performed_at: nil)).not_to be_valid
    end
  end

  it "encuentra la ultima visita completada de un vehiculo" do
    vehicle = create(:vehicle)
    vieja = create(:inspection, :completed, vehicle: vehicle, performed_at: 2.months.ago)
    reciente = create(:inspection, :completed, vehicle: vehicle, performed_at: 1.day.ago)
    create(:inspection, vehicle: vehicle)

    expect(described_class.latest_for(vehicle)).to eq(reciente)
    expect(described_class.latest_for(vehicle)).not_to eq(vieja)
  end
end
