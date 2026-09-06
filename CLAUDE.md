# maintenance-api

Backend Rails (API only) de **Maintenance**, app de mantenimiento predictivo vehicular.

## 1. Que hace este proyecto

Predice fallas de piezas usando **ingenieria de confiabilidad** (funciones de riesgo / curvas de
supervivencia tipo hazard function) en vez de tablas fijas de intervalos ("cambia el aceite cada
5.000 km"). La probabilidad de falla no es un numero fijo: es una curva que crece con el uso y se
ajusta por contexto real:

- Clima de la ciudad del usuario (bateria, llantas, cauchos)
- Terreno (Bogota montanoso desgasta distinto que Barranquilla plano)
- Estilo de manejo (a futuro, via OBD2)
- Marca especifica de los repuestos usados

La ventaja competitiva a largo plazo es la **data propia de los usuarios** (que pieza cambiaron,
cuando, en que ciudad, con que estilo de manejo), imposible de replicar con APIs externas genericas.

## 2. Decisiones de stack que el Gemfile no explica

- **PostgreSQL, nunca SQLite**: Render no persiste el filesystem.
- Las APIs externas se testean **siempre** con VCR o WebMock, jamas pegandole a la API real.
- El frontend Angular vive en el repo separado `maintenance-web`.

## 3. APIs externas (todas gratuitas)

| API | Uso |
|---|---|
| NHTSA VIN Decode | Decodifica marca/modelo/ano/motor desde el VIN (sin API key) |
| NHTSA Recalls | Recalls de seguridad activos por vehiculo |
| OpenWeatherMap (free tier) | Clima que afecta bateria, presion de llantas, desgaste |
| Fuel Economy (fueleconomy.gov) | Consumo real por modelo |
| datos.gov.co | Data abierta de transito/siniestralidad en Colombia |

Toda llamada externa va en `app/services/` y **siempre** se testea con VCR o WebMock, nunca
pegandole a la API real desde los specs.

**Limite importante de NHTSA:** solo cubre vehiculos homologados en EE.UU. Las motos que se venden
en Colombia (AKT, Bajaj, TVS, Auteco, Victory) **no estan**. Por eso el decode de VIN es un
**autocompletado oportunista** y nunca un requisito: si NHTSA no conoce el vehiculo o esta caida, el
registro manual tiene que seguir funcionando igual. Timeouts cortos, y `vin` es opcional en el
modelo.

## 4. Setup local

Lo estandar de Rails (`bundle install`, `bin/rails db:create db:migrate`, `bin/rails s`,
`bundle exec rspec`). Lo que no es adivinable:

- `cp .env.example .env`. Todas las claves son **opcionales**: sin `PLACAPI_API_KEY` el
  enriquecimiento del RUNT simplemente no ocurre y nada se rompe.
- `.env` no se commitea. Las variables de produccion se configuran en el dashboard de Render.

## 5. Base de datos en Render

- Servicio de PostgreSQL separado (Dashboard -> New -> PostgreSQL), vinculado al Web Service para
  que inyecte `DATABASE_URL`. `config/database.yml` ya lee `ENV["DATABASE_URL"]` en produccion.
- **El plan free de PostgreSQL expira a los 90 dias**: sirve para desarrollo, no para produccion
  real. Antes de produccion hay que definir plan pago + politica de backups, porque la data
  historica de usuarios es la ventaja competitiva del producto.
- Build Command en Render: `bundle install && bundle exec rails db:migrate` (migraciones
  automaticas en cada deploy).

## 6. Flujo de trabajo

### Ramas

`main` esta protegida y siempre desplegable. Nunca se commitea directo a `main`.
El trabajo diario va en ramas de tarea que salen de `staging`, y `staging` se mergea a `main`.

```
main                              <- protegida, siempre desplegable
 └─ staging                       <- integracion
     ├─ feature/12-vin-decode
     ├─ fix/15-null-check-vin
     └─ chore/8-setup-rspec-ci
```

Convencion: `tipo/numero-issue-descripcion-corta`
Tipos: `feature`, `fix`, `chore`, `refactor`, `test`, `docs`

Regla: **1 issue de GitHub = 1 rama = 1 Pull Request**.

### TDD (Red -> Green -> Refactor)

1. Escribir el spec primero: tiene que fallar.
2. Codigo minimo para que pase: verde.
3. Refactorizar con el spec en verde.

Ninguna tarea se marca "Done" sin tests escritos primero y pasando en CI.
Cobertura minima 80% (`MINIMUM_COVERAGE` en `spec/spec_helper.rb`).

### Commits — Conventional Commits

```
feat: agregar decodificacion de VIN via NHTSA API (#12)
fix: manejar VIN nulo en formulario de registro (#15)
test: agregar specs para RecallService (#13)
chore: configurar RSpec y SimpleCov (#8)
```

Los commits no llevan firma ni co-autoria de herramientas.

### Definition of Done

- [ ] Tests escritos antes del codigo y en verde
- [ ] Cobertura no baja del 80%
- [ ] CI en verde (RSpec + RuboCop + Brakeman + bundle-audit)
- [ ] Code review / autorevision con checklist
- [ ] Sin codigo muerto ni logs de debug
- [ ] Documentacion actualizada si aplica

### Scrum en GitHub

- Labels: `type:feature`, `type:bug`, `type:chore`, `priority:high/medium/low`, `size:S/M/L`
- Board: `Backlog` -> `Sprint Backlog` -> `In Progress` -> `In Review` -> `Done`
- Sprints = Milestones
- Cada issue lleva criterios de aceptacion (Given/When/Then) y checklist de Definition of Done

## 7. Modelo de dominio

La app arranca con **autos y motos**, pero el esquema tiene que soportar despues otras clases de
vehiculo (incluidas aereas y maritimas). Las reglas que sostienen eso:

- El modelo se llama `Vehicle`, tabla `vehicles`. **Una sola tabla, sin STI**: nada de clases `Car`
  o `Motorcycle`. Lo especifico de una clase va en `jsonb specs`.
- `vehicle_type` es un enum **de strings** (`car`, `motorcycle` hoy). Strings y no enteros para que
  agregar valores no dependa del orden.
- **El uso se guarda como `usage_value` + `usage_unit`, nunca como kilometraje suelto.** `km` para
  terrestres, `hours` para lo aereo/maritimo que venga. Las curvas de riesgo consumen esta variable:
  amarrarla a km amarraria toda la matematica del producto.
- Las piezas viven en el catalogo `part_types`, **nunca hardcodeadas**. Una moto tiene cadena y kit
  de arrastre; un auto tiene correa de repartición.
- `vin` es **opcional** y unico solo cuando esta presente (indice unico parcial). Validar 17
  caracteres sin I, O ni Q (estandar ISO 3779).
- `model_year`, no `year`: reservada en SQL y ambigua frente al ano de registro.

## 8. Convenciones de codigo

- Codigo y base de datos **en ingles**; los textos en espanol viven en el frontend. No se mezclan
  los dos idiomas dentro del mismo modelo.
- Logica de negocio en `app/services/`, no en controllers ni models gordos.
- Los controllers responden JSON y nada mas; sin logica de dominio.
- Los calculos de confiabilidad (hazard functions, curvas de supervivencia) van en objetos propios
  y bien testeados: son el corazon del producto.
- RuboCop con `rubocop-rails-omakase`.
