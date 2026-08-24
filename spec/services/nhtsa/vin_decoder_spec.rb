require "rails_helper"

RSpec.describe Nhtsa::VinDecoder do
  subject(:decoder) { described_class.new }

  describe "#call", :vcr do
    it "decodifica un auto homologado en EE.UU." do
      result = decoder.call("5YJ3E1EA6PF384836")

      expect(result).to be_found
      expect(result.make).to eq("TESLA")
      expect(result.model).to eq("Model 3")
      expect(result.model_year).to eq(2023)
      expect(result.vehicle_type).to eq("car")
    end

    it "decodifica una moto y la mapea a nuestro enum" do
      result = decoder.call("JH2PC35051M200020")

      expect(result).to be_found
      expect(result.make).to eq("HONDA")
      expect(result.vehicle_type).to eq("motorcycle")
    end

    it "devuelve vacio para un vehiculo no homologado en EE.UU." do
      # Caso tipico colombiano: NHTSA solo cubre vehiculos homologados en EE.UU.
      result = decoder.call("9FBLSRB56KM123456")

      expect(result).not_to be_found
      expect(result.make).to be_nil
    end
  end

  describe "#call sin salir a la red" do
    it "no consulta el API si el VIN no tiene formato valido" do
      result = decoder.call("NOTAVIN")

      expect(result).not_to be_found
      expect(a_request(:get, /vpic.nhtsa.dot.gov/)).not_to have_been_made
    end

    it "no consulta el API si el VIN viene vacio" do
      expect(decoder.call(nil)).not_to be_found
      expect(a_request(:get, /vpic.nhtsa.dot.gov/)).not_to have_been_made
    end

    it "normaliza el VIN antes de consultar" do
      stub = stub_request(:get, %r{DecodeVinValues/5YJ3E1EA6PF384836})
        .to_return(status: 200, body: { "Results" => [] }.to_json, headers: { "Content-Type" => "application/json" })

      decoder.call(" 5yj3e1ea6pf384836 ")

      expect(stub).to have_been_made
    end
  end

  describe "#call cuando el API falla" do
    it "devuelve vacio si el API no responde a tiempo" do
      stub_request(:get, /vpic.nhtsa.dot.gov/).to_timeout

      expect(decoder.call("5YJ3E1EA6PF384836")).not_to be_found
    end

    it "devuelve vacio si el API responde con error del servidor" do
      stub_request(:get, /vpic.nhtsa.dot.gov/).to_return(status: 500, body: "")

      expect(decoder.call("5YJ3E1EA6PF384836")).not_to be_found
    end

    it "devuelve vacio si el API responde algo que no es JSON" do
      stub_request(:get, /vpic.nhtsa.dot.gov/)
        .to_return(status: 200, body: "<html>mantenimiento</html>", headers: { "Content-Type" => "text/html" })

      expect(decoder.call("5YJ3E1EA6PF384836")).not_to be_found
    end

    it "devuelve vacio si el API responde sin resultados" do
      stub_request(:get, /vpic.nhtsa.dot.gov/)
        .to_return(status: 200, body: { "Results" => [] }.to_json, headers: { "Content-Type" => "application/json" })

      expect(decoder.call("5YJ3E1EA6PF384836")).not_to be_found
    end

    it "nunca levanta una excepcion: el registro manual tiene que seguir funcionando" do
      stub_request(:get, /vpic.nhtsa.dot.gov/).to_raise(Faraday::ConnectionFailed)

      expect { decoder.call("5YJ3E1EA6PF384836") }.not_to raise_error
    end
  end

  describe "mapeo de tipos de vehiculo" do
    it "trata una camioneta MPV como auto" do
      stub_nhtsa_vehicle_type("MULTIPURPOSE PASSENGER VEHICLE (MPV)")

      expect(decoder.call("5YJ3E1EA6PF384836").vehicle_type).to eq("car")
    end

    it "deja el tipo en blanco cuando es una clase que todavia no soportamos" do
      stub_nhtsa_vehicle_type("TRUCK")

      expect(decoder.call("5YJ3E1EA6PF384836").vehicle_type).to be_nil
    end

    def stub_nhtsa_vehicle_type(vehicle_type)
      body = { "Results" => [ { "Make" => "X", "Model" => "Y", "ModelYear" => "2020", "VehicleType" => vehicle_type } ] }
      stub_request(:get, /vpic.nhtsa.dot.gov/)
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end
  end
end
