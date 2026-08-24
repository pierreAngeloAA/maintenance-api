require "rails_helper"

RSpec.describe Nhtsa::RecallsFetcher do
  subject(:fetcher) { described_class.new }

  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before { allow(Rails).to receive(:cache).and_return(memory_cache) }

  describe "#call", :vcr do
    it "devuelve los recalls activos de un vehiculo conocido" do
      recalls = fetcher.call(make: "honda", model: "accord", model_year: 2020)

      expect(recalls).not_to be_empty
      expect(recalls.first.campaign_number).to be_present
      expect(recalls.first.component).to be_present
      expect(recalls.first.summary).to be_present
    end

    it "parsea la fecha del reporte, que NHTSA manda como MM/DD/AAAA" do
      recalls = fetcher.call(make: "honda", model: "accord", model_year: 2020)

      expect(recalls.first.reported_on).to be_a(Date)
    end

    it "devuelve vacio para un vehiculo que NHTSA no cubre" do
      # AKT es una marca colombiana: NHTSA no la conoce.
      recalls = fetcher.call(make: "akt", model: "nkd", model_year: 2021)

      expect(recalls).to eq([])
    end
  end

  describe "cache" do
    before do
      stub_request(:get, /api.nhtsa.gov/).to_return(
        status: 200,
        body: { "Count" => 1, "results" => [ { "NHTSACampaignNumber" => "20V771000" } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "no vuelve a consultar el API por el mismo vehiculo: los recalls no cambian a diario" do
      fetcher.call(make: "honda", model: "accord", model_year: 2020)
      fetcher.call(make: "honda", model: "accord", model_year: 2020)

      expect(a_request(:get, /api.nhtsa.gov/)).to have_been_made.once
    end

    it "consulta de nuevo para un vehiculo distinto" do
      fetcher.call(make: "honda", model: "accord", model_year: 2020)
      fetcher.call(make: "honda", model: "civic", model_year: 2020)

      expect(a_request(:get, /api.nhtsa.gov/)).to have_been_made.twice
    end

    it "trata la marca y el modelo sin importar mayusculas" do
      fetcher.call(make: "honda", model: "accord", model_year: 2020)
      fetcher.call(make: "HONDA", model: "Accord", model_year: 2020)

      expect(a_request(:get, /api.nhtsa.gov/)).to have_been_made.once
    end
  end

  describe "cuando faltan datos o el API falla" do
    it "no consulta el API si el vehiculo no tiene marca, modelo o ano" do
      expect(fetcher.call(make: "", model: "accord", model_year: 2020)).to eq([])
      expect(fetcher.call(make: "honda", model: nil, model_year: 2020)).to eq([])
      expect(fetcher.call(make: "honda", model: "accord", model_year: nil)).to eq([])
      expect(a_request(:get, /api.nhtsa.gov/)).not_to have_been_made
    end

    it "devuelve vacio si el API no responde a tiempo" do
      stub_request(:get, /api.nhtsa.gov/).to_timeout

      expect(fetcher.call(make: "honda", model: "accord", model_year: 2020)).to eq([])
    end

    it "devuelve vacio si el API responde con error del servidor" do
      stub_request(:get, /api.nhtsa.gov/).to_return(status: 503, body: "")

      expect(fetcher.call(make: "honda", model: "accord", model_year: 2020)).to eq([])
    end

    it "no guarda en cache una respuesta fallida" do
      stub_request(:get, /api.nhtsa.gov/).to_return(status: 503, body: "")

      fetcher.call(make: "honda", model: "accord", model_year: 2020)
      fetcher.call(make: "honda", model: "accord", model_year: 2020)

      expect(a_request(:get, /api.nhtsa.gov/)).to have_been_made.twice
    end

    it "tolera una fecha de reporte con formato raro" do
      stub_request(:get, /api.nhtsa.gov/).to_return(
        status: 200,
        body: { "results" => [ { "NHTSACampaignNumber" => "X", "ReportReceivedDate" => "ayer" } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect(fetcher.call(make: "honda", model: "accord", model_year: 2020).first.reported_on).to be_nil
    end
  end
end
