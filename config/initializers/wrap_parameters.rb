# Los clientes de este API mandan siempre la raiz explicita (`{"vehicle": {...}}`),
# asi que el wrapping automatico sobra. Ademas hace dano: crea una clave
# snake_case vacia que choca con la del body cuando pasamos camelCase a
# snake_case, y el request termina en 400.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters false
end
