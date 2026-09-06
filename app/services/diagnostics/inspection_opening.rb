module Diagnostics
  # Abre una inspeccion con la plantilla vigente para esa clase de vehiculo.
  #
  # La plantilla queda amarrada a la inspeccion, no se resuelve al leer: cuando
  # se publique la version siguiente del checklist, las inspecciones viejas
  # tienen que seguir mostrando los campos con los que se hicieron.
  class InspectionOpening
    Result = Data.define(:inspection, :error) do
      def success? = error.nil?
    end

    def initialize(vehicle:, technician:, organization:, attributes:)
      @vehicle = vehicle
      @technician = technician
      @organization = organization
      @attributes = attributes
    end

    def call
      template = InspectionTemplate.current_for(vehicle.vehicle_type)
      return failure(:no_template) if template.nil?

      existing = open_inspection_for(template)
      return Result.new(inspection: existing, error: nil) if existing

      Result.new(inspection: create(template), error: nil)
    rescue ActiveRecord::RecordInvalid
      failure(:invalid)
    end

    private

    attr_reader :vehicle, :technician, :organization, :attributes

    # Si el tecnico ya tenia una abierta para este vehiculo, se retoma en vez de
    # empezar otra: se le cerro la app, no cambio de trabajo.
    def open_inspection_for(_template)
      Inspection.find_by(
        vehicle: vehicle, technician_user: technician,
        organization: organization, status: "in_progress"
      )
    end

    def create(template)
      Inspection.create!(
        vehicle: vehicle, template: template, technician_user: technician,
        organization: organization, started_at: Time.current,
        usage_value: attributes[:usage_value],
        service_order_id: attributes[:service_order_id]
      )
    end

    def failure(error)
      Result.new(inspection: nil, error: error)
    end
  end
end
