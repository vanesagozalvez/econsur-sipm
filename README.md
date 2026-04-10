# EconSur · SIPM Argentina 🇦🇷

Dashboard interactivo con la serie histórica del **Sistema de Índices de Precios Mayoristas (SIPM)** publicado por el INDEC.

## Índices incluidos

| Sigla | Descripción | Base |
|-------|------------|------|
| **IPIM** | Índice de Precios Internos al por Mayor | Dic-2015 = 100 |
| **IPIB** | Índice de Precios Internos Básicos al por Mayor | Dic-2015 = 100 |
| **IPP** | Índice de Precios Básicos del Productor | Dic-2015 = 100 |

## Stack

| Capa | Tecnología |
|------|-----------|
| Lenguaje | R 4.3 |
| UI framework | bs4Dash + Shiny |
| Gráficos | Highcharter |
| Deploy | Render (Docker) |
| Datos | INDEC – CSVs SIPM |

## Estructura del repositorio

```
econsur-sipm/
├── app.R                    # App principal (UI + Server + ETL)
├── data/
│   ├── indice_ipim.csv      # IPIM – Precios Internos al por Mayor
│   ├── indice_ipib.csv      # IPIB – Precios Internos Básicos al por Mayor
│   └── indice_ipp.csv       # IPP  – Precios Básicos del Productor
├── Dockerfile               # Imagen Docker para Render
├── shiny-server.conf        # Config Shiny Server (PORT dinámico)
├── render.yaml              # Blueprint de Render
└── .gitignore
```

## Vistas del dashboard

| Tab | Descripción |
|-----|------------|
| **Principal – SIPM** | KPIs mensual + interanual de los 3 índices. Gráfico comparativo de evolución (nivel / mensual / interanual). Barras de variación último mes. |
| **IPIM** | Componentes del IPIM (Primarios, Ind. Manuf. y Energía, Importados) vs Nivel General. Líneas históricas + barras último mes. |
| **IPIB** | Componentes del IPIB (Primarios, Ind. Manuf. y Energía, Importados) vs Nivel General. Líneas históricas + barras último mes. |
| **IPP** | Componentes del IPP (Primarios, Ind. Manuf. y Energía) vs Nivel General. Líneas históricas + barras último mes. |
| **Acerca de** | Info del proyecto y fuentes. |

## Componentes graficados por índice

| Componente | IPIM | IPIB | IPP |
|-----------|------|------|-----|
| Nivel General | ✓ | ✓ | ✓ |
| Primarios | ✓ | ✓ | ✓ |
| Ind. Manuf. y Energía | ✓ | ✓ | ✓ |
| Importados | ✓ | ✓ | – |

## Métricas disponibles (selector en cada tab)

- **Nivel (base 100):** evolución del índice desde dic-2015
- **Variación Mensual %:** cambio respecto al mes anterior
- **Variación Interanual %:** acumulado 12 meses rolling (calculado desde variaciones mensuales)

## Deploy en Render

1. Crear repo en GitHub y subir todos los archivos (incluyendo la carpeta `data/`).
2. En [render.com](https://render.com) → **New → Web Service**.
3. Conectar el repo de GitHub.
4. Render detecta `render.yaml` automáticamente:
   - **Runtime:** Docker
   - **Dockerfile path:** `./Dockerfile`
   - **Port:** `3838`
5. Click en **Create Web Service**.

> El primer build tarda ~8-12 min por la instalación de paquetes R.  
> Los builds siguientes son más rápidos gracias al cache de Docker.

## Actualización de datos

Reemplazar los archivos en `data/` y hacer push al repo.  
Render redespliega automáticamente.

---

**Fuente:** [INDEC Argentina](https://www.indec.gob.ar/) – Dirección Nacional de Estadísticas de Precios.  
**Nota:** El último mes publicado es dato provisorio.
