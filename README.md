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
