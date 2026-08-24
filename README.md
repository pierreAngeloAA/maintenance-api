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

## Endpoints

Base: `/api/v1`. El API habla **camelCase** con el frontend (`vehicleType`, `usageValue`) y
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
