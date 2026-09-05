module Identity
  # Registro de una organizacion por parte de quien la crea.
  #
  # Quien la registra queda como `owner` y su membresia nace ya aceptada: no se
  # invita a si mismo. Es el camino del tecnico independiente, que es un taller
  # de una sola persona. El otro camino, el del empleado, es al reves: el dueno
  # invita y la persona acepta.
  class OrganizationRegistration
    def initialize(user, attributes)
      @user = user
      @attributes = attributes
    end

    def call
      organization = Organization.new(attributes)

      Organization.transaction do
        organization.save!
        organization.memberships.create!(user: user, role: "owner", accepted_at: Time.current)
      end

      organization
    rescue ActiveRecord::RecordInvalid
      organization
    end

    private

    attr_reader :user, :attributes
  end
end
