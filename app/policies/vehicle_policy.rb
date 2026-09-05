# Quien puede ver y escribir sobre un vehiculo.
#
# Hasta ahora el alcance se resolvia solo con la consulta (`current_user.vehicles`),
# porque el unico actor era el dueno. Con permisos delegados eso deja de alcanzar:
# un taller puede tocar un vehiculo que no es suyo, pero solo mientras tenga un
# permiso vigente y del alcance correcto.
module VehiclePolicy
  module_function

  def read?(vehicle)
    owner?(vehicle) || granted?(vehicle, :read)
  end

  def write?(vehicle)
    owner?(vehicle) || granted?(vehicle, :write)
  end

  def owner?(vehicle)
    Current.client? && vehicle.user_id == Current.user&.id
  end

  def granted?(vehicle, level)
    return false if Current.organization.nil?

    vehicle.access_grants.active.allowing(level)
      .exists?(organization_id: Current.organization.id)
  end
end
