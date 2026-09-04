# maintenance-api

Backend en Ruby on Rails (API only) de **Maintenance**: app de mantenimiento predictivo vehicular.

En vez de usar tablas genericas de intervalos de servicio ("cambia el aceite cada 5.000 km"), la app
modela la probabilidad de falla de cada pieza como una **curva de riesgo** que crece con el uso y se
ajusta por el contexto real del vehiculo: clima de la ciudad, terreno, estilo de manejo y marca de
los repuestos instalados.

El frontend Angular esta en el repo [`maintenance-web`](../maintenance-web).

## Stack

- Ruby 3.3 / Rails 8.1 (`--api`)
- PostgreSQL
- RSpec, FactoryBot, SimpleCov, WebMock, VCR
- Despliegue en Render

## Setup

Requisitos: Ruby 3.3.5, PostgreSQL 16 corriendo localmente.

```bash
git clone git@github.com:pierreAngeloAA/maintenance-api.git
cd maintenance-api
bundle install
cp .env.example .env
bin/rails db:create db:migrate
bin/rails s
```

La API queda en `http://localhost:3000`. Health check: `GET /up`.

## Autenticacion

Todos los endpoints exigen sesion, salvo el registro y el inicio de sesion. Se autentica con un
token bearer:

```bash
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/vehicles
```

| endpoint | que hace |
|---|---|
| `POST /api/v1/users` | Registro. Devuelve el usuario y un token listo para usar. |
| `POST /api/v1/sessions` | Inicio de sesion. Devuelve usuario y token. |
| `DELETE /api/v1/sessions` | Cierra **esa** sesion; las otras sesiones del usuario siguen vivas. |
| `GET /api/v1/me` | Usuario de la sesion actual. |

```bash
curl -X POST http://localhost:3000/api/v1/sessions \
  -H "Content-Type: application/json" \
  -d '{"session":{"email":"pierre@example.com","password":"unaClaveSegura1"}}'
```

Detalles que importan:

- En la base de datos se guarda el **digest** del token, nunca el token: leer la tabla `sessions` no
  alcanza para hacerse pasar por nadie.
- Credenciales invalidas siempre responden lo mismo (`{"error":"invalid_credentials"}`), sin
  distinguir entre correo inexistente y contrasena equivocada: lo contrario revelaria quien esta
  registrado.
- Cada vehiculo pertenece a un usuario. Pedir el vehiculo de otro responde **404**, no 403, para no
  confirmar que existe.
- Los endpoints nacen protegidos: hay que marcarlos explicitamente con `allow_unauthenticated_access`
  para abrirlos. Es preferible que un endpoint nuevo quede cerrado por olvido a que quede abierto.

## Endpoints

Base: `/api/v1`. Todos exigen la cabecera `Authorization: Bearer <token>`. El API habla **camelCase** con el frontend (`vehicleType`, `usageValue`) y
snake_case internamente. Los decimales viajan como string (`"45000.0"`) para no perder precision.

### `GET /api/v1/vehicles`

Lista los vehiculos, el mas reciente primero.

```bash
curl http://localhost:3000/api/v1/vehicles
```

### `POST /api/v1/vehicles`

Crea un vehiculo. **El VIN es opcional**: una moto colombiana se registra sin el.

```bash
curl -X POST http://localhost:3000/api/v1/vehicles \
  -H "Content-Type: application/json" \
  -d '{"vehicle":{"vehicleType":"motorcycle","make":"AKT","model":"NKD 125",
       "modelYear":2021,"plate":"abc12d","usageValue":12000,"usageUnit":"km",
       "city":"Medellin"}}'
```

```json
{
  "id": 2,
  "vehicleType": "motorcycle",
  "make": "AKT",
  "model": "NKD 125",
  "modelYear": 2021,
  "vin": null,
  "plate": "ABC12D",
  "usageValue": "12000.0",
  "usageUnit": "km",
  "city": "Medellin",
  "specs": {},
  "createdAt": "2026-08-24T19:56:42.968Z",
  "updatedAt": "2026-08-24T19:56:42.968Z"
}
```

`201` si se creo, `422` con los errores por campo si no:

```json
{ "errors": { "make": ["can't be blank"],
              "modelYear": ["must be greater than or equal to 1900"] } }
```

Los mensajes de error **no son texto de interfaz**: el frontend arma el mensaje en espanol a
partir del nombre del campo.

### `GET /api/v1/vehicles/:id`

Devuelve el vehiculo mas `partTypes`, las piezas del catalogo que aplican a esa clase de vehiculo
(una moto trae cadena y kit de arrastre; un auto trae correa de repartición). `404` si no existe:

```json
{ "error": "not_found" }
```

### `GET` y `POST /api/v1/vehicles/:vehicle_id/maintenance_records`

Historial de mantenimientos: que pieza se cambio, cuando, con cuanto uso y de que marca. **Es la
data que alimenta el modelo de riesgo** y la que ninguna API externa puede dar.

```bash
curl -X POST http://localhost:3000/api/v1/vehicles/1/maintenance_records \
  -H "Content-Type: application/json" \
  -d '{"maintenanceRecord":{"partTypeId":17,"performedOn":"2026-07-15",
       "usageAtService":12000,"partBrand":"DID","costCents":18000000,"currency":"COP"}}'
```

El listado viene con lo mas reciente primero. `422` si la pieza no aplica a esa clase de vehiculo
(no se le cambia la cadena a un auto) o si el uso del mantenimiento supera el uso actual del
vehiculo.

### `GET /api/v1/vehicles/:vehicle_id/risks`

Riesgo de falla por pieza, de mayor a menor. Acepta `?horizon=5000` para cambiar el tramo sobre el
que se calcula el riesgo condicional; un valor invalido se ignora y se usa el tramo por defecto.

```json
{
  "vehicleId": 1,
  "risks": [
    {
      "partType": { "code": "drive_chain", "name": "Cadena de transmision" },
      "usageSinceService": 6000.0,
      "basis": "last_service",
      "lifeUnit": "km",
      "failureProbability": 0.0861,
      "conditionalRisk": 0.0298,
      "horizon": 1000,
      "estimate": true,
      "contextFactor": 0.9
    }
  ]
}
```

- `failureProbability` = `1 - R(t)`: que tan probable es que la pieza ya haya llegado al final de su vida.
- `conditionalRisk` = `1 - R(t+Δt)/R(t)`: riesgo de falla en el proximo tramo, dado que llego sana hasta `t`. **Es el numero util.**
- `basis` dice de donde salio `t`: `last_service` (hay historial), `vehicle_total` (la pieza nunca se cambio) o `model_year` (pieza que se degrada con el tiempo, sin historial).
- `estimate: true` significa que β y η todavia son estimaciones de ingenieria, no numeros calculados con datos de usuarios. **La interfaz tiene que decirlo.**
- `contextFactor` es el ajuste por el contexto de la ciudad del vehiculo (ver abajo). `1.0` es sin ajuste.

#### Ajuste por contexto

El mismo repuesto no dura lo mismo en Bogota que en Barranquilla. Se modela como **vida acelerada**:

```
η_efectiva = η × Π(factores)
```

El contexto **no cambia la matematica del riesgo**: solo acorta la vida caracteristica de la pieza.
Hoy se ajusta por dos dimensiones, resueltas desde `vehicles.city`:

- **Terreno**: una ciudad montanosa castiga frenos, clutch y llantas.
- **Clima**: el calor castiga la bateria y el sol y la humedad castigan los cauchos.

Los factores viven en `config/context_factors.yml`, no en codigo: agregar una ciudad o recalibrar un
castigo es editar YAML. **Un factor ausente vale 1,0 y nunca rompe el calculo**: un vehiculo sin
ciudad, o en una ciudad que no esta en el catalogo, da exactamente el mismo resultado que antes de
existir este ajuste.

La misma moto AKT con 18.000 km, en dos ciudades:

| pieza | Bogota | Barranquilla |
|---|---|---|
| Bandas de freno | 17,66% | 10,53% |
| Cadena de transmision | 15,08% | 11,46% |
| Guaya de clutch | 11,87% | 8,11% |
| Bateria | 43,50% | **58,42%** |
| Filtro de aceite | 99,14% | 99,14% |

La inversion de la bateria es el punto: en la montana mandan los frenos, en el calor manda la
bateria. El filtro de aceite no lo toca ningun factor y queda igual en las dos.

Como los parametros de Weibull, **estos factores son estimaciones de ingenieria iniciales**, no
datos medidos, y estan puestos para recalibrarse cuando haya volumen real de mantenimientos por
ciudad.

### `GET /api/v1/vehicles/:vehicle_id/recalls`

Recalls de seguridad reportados por NHTSA. **Siempre responde `200` con una lista**, aunque este
vacia: como NHTSA solo cubre EE.UU., no encontrar recalls es un resultado normal y no significa que
el vehiculo no tenga problemas. La respuesta se cachea 24 horas.

```json
{
  "vehicleId": 1,
  "recalls": [
    {
      "campaignNumber": "20V771000",
      "manufacturer": "Honda (American Honda Motor Co.)",
      "component": "ELECTRICAL SYSTEM:BODY CONTROL MODULE:SOFTWARE",
      "summary": "...",
      "consequence": "...",
      "remedy": "...",
      "reportedOn": "2020-10-12",
      "parkIt": false,
      "parkOutside": false
    }
  ]
}
```

`parkIt` y `parkOutside` son las banderas graves de NHTSA: el vehiculo no deberia manejarse, o no
deberia parquearse bajo techo por riesgo de incendio.

### `GET /api/v1/vin_lookups/:vin`

Autocompletado del formulario a partir del VIN. **Siempre responde `200`**, incluso cuando no
encuentra el vehiculo: que NHTSA no lo conozca no es un error, y el registro manual tiene que
seguir funcionando.

```bash
curl http://localhost:3000/api/v1/vin_lookups/JH2PC35051M200020
```

```json
{ "vin": "JH2PC35051M200020", "found": true, "make": "HONDA",
  "model": "CBR600F", "modelYear": 2001, "vehicleType": "motorcycle" }
```

Con un vehiculo que NHTSA no cubre — tipico en Colombia, incluidos los Renault ensamblados aca:

```json
{ "vin": "9FBLSRB56KM123456", "found": false, "make": null,
  "model": null, "modelYear": null, "vehicleType": null }
```

El servicio no sale a la red si el VIN no cumple el formato ISO 3779, y ante timeout o caida de
NHTSA responde igual con `found: false`.

## Tests

```bash
bundle exec rspec              # suite completa + reporte de cobertura
bundle exec rubocop            # estilo
bundle exec brakeman           # analisis de seguridad
```

La cobertura minima es 80%; el reporte HTML queda en `coverage/index.html`.

## Como se trabaja

TDD estricto (test primero), una rama por issue, Conventional Commits y `main` protegida.
El detalle esta en [`CLAUDE.md`](CLAUDE.md).

## Licencia

MIT
