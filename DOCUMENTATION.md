# BlackSignal - Documentación del Proyecto

## Información General

**Nombre:** BlackSignal
**Versión WoW:** 12.0.0 (The War Within)
**Tipo:** Addon de World of Warcraft
**Propósito:** Mejoras de calidad de vida (Quality of Life) mediante módulos modulares
**Autores:** Xaico, Gwydeon
**ID Wago:** QN53BPKB
**ID Curse:** 1452012

---

## Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Estructura de Directorios](#estructura-de-directorios)
3. [Sistemas Core](#sistemas-core)
4. [Patrón de Módulos](#patrón-de-módulos)
5. [Guía de Creación de Módulos](#guía-de-creación-de-módulos)
6. [Eventos Disponibles](#eventos-disponibles)
7. [Controles UI Personalizados](#controles-ui-personalizados)
8. [Convenciones de Código](#convenciones-de-código)
9. [Módulos Existentes](#módulos-existentes)

---

## Arquitectura General

BlackSignal utiliza una arquitectura modular centrada en un framework core compartido. Todos los módulos se registran en un sistema centralizado que maneja su inicialización, configuración y eventos.

```
┌─────────────────────────────────────────────────────────┐
│                    BlackSignal (BS)                     │
├─────────────────────────────────────────────────────────┤
│  Core Systems                                          │
│  ├── API (Registro y carga de módulos)                 │
│  ├── DB (Persistencia de configuración)                │
│  ├── Events (Dispatch de eventos)                      │
│  ├── Movers (Posicionamiento UI)                       │
│  ├── Tickers (Actualizaciones periódicas)              │
│  └── Utils (Funciones auxiliares)                      │
├─────────────────────────────────────────────────────────┤
│  Configuration System                                  │
│  ├── MainPanel (Ventana principal 840x600)             │
│  ├── LeftPanel (Lista de módulos)                      │
│  ├── RightPanel (Config por módulo)                    │
│  └── MinimapButton (Botón minimapa)                    │
├─────────────────────────────────────────────────────────┤
│  UI Framework                                          │
│  ├── Button, CheckButton, EditBox, ColorPicker        │
│  └── Colors (Tema púrpura: 127,63,191)                │
├─────────────────────────────────────────────────────────┤
│  Modules                                               │
│  ├── AutoQueue                                         │
│  ├── BuffTracker (con Data/Engine/UI separados)       │
│  ├── CombatTime                                        │
│  ├── EnemyCastList                                     │
│  ├── FocusCastTracker                                  │
│  ├── MouseRing                                         │
│  ├── Shimmer                                           │
│  └── TeleportButtons                                   │
└─────────────────────────────────────────────────────────┘
```

---

## Estructura de Directorios

```
BlackSignal/
├── Core/                          # Framework y sistemas core
│   ├── API.lua                    # Sistema de registro de módulos
│   ├── DB.lua                     # SavedVariables y persistencia
│   ├── Events.lua                 # Sistema de eventos centralizado
│   ├── Init.lua                   # Mensaje de carga
│   ├── Utils.lua                  # Funciones utilitarias
│   ├── Tickers.lua                # Sistema de timers/actualizaciones
│   ├── Movers.lua                 # Sistema de posicionamiento UI
│   │
│   ├── Config/                    # Sistema de configuración
│   │   ├── Config.lua             # Comandos slash e inicialización
│   │   ├── MainPanel.lua          # Ventana principal
│   │   ├── LeftPanel.lua          # Panel izquierdo (lista)
│   │   ├── RightPanel.lua         # Panel derecho (opciones)
│   │   └── Minimap.lua            # Botón de minimapa
│   │
│   ├── Controls/                  # Componentes UI reutilizables
│   │   ├── Button.lua             # Botón personalizado
│   │   ├── CheckButton.lua        # Checkbox con texto de info
│   │   ├── EditBox.lua            # Caja de texto
│   │   └── ColorPicker.lua        # Selector de color
│   │
│   └── UI/                        # Utilidades UI
│       ├── UI.lua                 # Funciones helper UI
│       └── Colors.lua             # Definición de colores/tema
│
├── Modules/                       # Módulos de funcionalidad
│   ├── AutoQueue/
│   ├── BuffTracker/
│   │   ├── BuffTracker.lua        # Módulo principal
│   │   ├── Data.lua               # Datos de buffs
│   │   ├── Engine.lua             # Lógica de negocio
│   │   └── UI.lua                 # Renderizado UI
│   ├── CombatTime/
│   ├── EnemyCastList/
│   ├── FocusCastTracker/
│   ├── MouseRing/
│   ├── Shimmer/
│   └── TeleportButtons/
│
├── Media/                         # Recursos gráficos
│   ├── icon                       # Icono del addon (.toc IconTexture)
│   ├── icon_32.png                # Icono para minimapa
│   ├── icon_64.tga                # Icono para panel principal
│   ├── ArrowUp.tga                # Flechas para sistema de movers
│   ├── Close.tga                  # Icono de cerrar panel
│   ├── Ring_10px.tga              # Textura de anillo 10px
│   ├── Ring_20px.tga              # Textura de anillo 20px (default)
│   ├── Ring_30px.tga              # Textura de anillo 30px
│   └── Ring_40px.tga              # Textura de anillo 40px
│
├── BlackSignal.toc                # Table of Contents
└── DOCUMENTATION.md               # Este archivo
```

---

## Sistemas Core

### API (Core/API.lua)

Sistema central de registro y carga de módulos.

**Funciones principales:**

```lua
-- Registrar un módulo en el sistema
BS.API:Register(module)

-- Cargar e inicializar todos los módulos registrados
BS.API:Load()
```

**Propiedades del módulo:**
- `modules`: Tabla de todos los módulos registrados
- Filtrado por clase (`module.classes`)
- Prevención de doble inicialización (`__initialized`)

---

### DB (Core/DB.lua)

Sistema de persistencia de configuración usando SavedVariables.

**Estructura de la base de datos:**
```lua
BlackSignalDB = {
    profile = {
        modules = {
            ["BS_NOMBRE_MODULO"] = {
                enabled = true,
                -- configuración específica del módulo
            }
        },
        minimap = {
            -- configuración del botón de minimapa
        }
    }
}
```

**Funciones principales:**
```lua
-- Asegura que exista la DB del módulo con valores por defecto
local db = BS.DB:EnsureDB(moduleName, defaults)

-- DB para el botón de minimapa
local db = BS.DB:MinimapDB(defaults)
```

**Importante:** Solo escribe en la DB valores que necesiten persistencia entre sesiones.

---

### Events (Core/Events.lua)

Sistema centralizado de dispatch de eventos a módulos.

**Registro de eventos:**
```lua
-- Evento normal
Events:RegisterEvent("PLAYER_LOGIN")

-- Evento de unidad con filtro
Events:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
```

**Manejo de eventos en módulos:**
```lua
Module.events.PLAYER_LOGIN = function(self)
    -- código
end

Module.events.UNIT_AURA = function(self, unit)
    if unit ~= "player" then return end
    -- código
end
```

**Eventos core registrados automáticamente:**
- `PLAYER_LOGIN` - Dispara `API:Load()`
- `PLAYER_SPECIALIZATION_CHANGED`
- `TRAIT_CONFIG_UPDATED`
- `ACTIVE_TALENT_GROUP_CHANGED`

---

### Tickers (Core/Tickers.lua)

Sistema para actualizaciones periódicas (alternativa a OnUpdate).

```lua
-- Registrar un ticker
BS.Tickers:Register(self, intervaloSegundos, funcion)

-- Detener ticker de un módulo
BS.Tickers:Stop(self)
```

**Ejemplo de uso:**
```lua
function Module:StartTicker()
    BS.Tickers:Stop(self) -- Detener anterior si existe
    BS.Tickers:Register(self, 1, function()
        self:Update()
    end)
end
```

---

### Movers (Core/Movers.lua)

Sistema para hacer movibles los frames de los módulos.

```lua
-- Registrar un frame como movible
BS.Movers:Register(frame, key, label)

-- Controlar el modo movers
BS.Movers:Toggle()   -- Alternar
BS.Movers:Unlock()   -- Activar modo edición
BS.Movers:Lock()     -- Desactivar modo edición

-- Resetear posiciones
BS.Movers:Reset(key)     -- Reset individual
BS.Movers:ResetAll()     -- Reset todos
```

**Propiedades requeridas en la DB del módulo:**
```lua
local defaults = {
    x = 0,  -- Offset X desde el centro
    y = 0,  -- Offset Y desde el centro
}
```

**Comandos slash:**
- `/bs movers` o `/bs movers toggle` - Alternar modo
- `/bs movers on` o `/bs movers unlock` - Activar
- `/bs movers off` o `/bs movers lock` - Desactivar
- `/bs movers reset` - Resetear todos

**Funciones del mover overlay:**
- Click izquierdo: Activar controles (coordenadas + flechas)
- Click derecho: Resetear posición
- Arrastrar: Mover el frame
- Flechas: Nudge (1px normal, 10px con Shift)
- ESC: Cerrar modo movers

---

## Patrón de Módulos

### Estructura Básica

Todo módulo debe seguir esta estructura:

```lua
-- Modules/MyModule/MyModule.lua
-- @module MyModule
-- @alias MyModule

local _, BS = ...
local DB     = BS.DB
local API    = BS.API
local Events = BS.Events

local MyModule = {
    name    = "BS_MYMODULE",      -- Identificador único (requerido)
    label   = "My Module",        -- Nombre visible (requerido)
    enabled = true,               -- Habilitado por defecto
    events  = {},                 -- Table de handlers de eventos
    classes = nil,                -- Filtro de clase (opcional)
    hidden  = false,              -- Ocultar del config (opcional)
}

-- Registrar el módulo
API:Register(MyModule)

-------------------------------------------------
-- Defaults (Configuración por defecto)
-------------------------------------------------
local defaults = {
    enabled     = true,
    -- Propiedades específicas del módulo
}

MyModule.defaults = defaults

-------------------------------------------------
-- OnInit: Inicialización del módulo
-------------------------------------------------
function MyModule:OnInit()
    -- Cargar configuración
    self.db = DB:EnsureDB(self.name, defaults)
    self.enabled = (self.db.enabled ~= false)

    -- Crear UI
    -- Registrar eventos
    -- Iniciar tickers si es necesario
end

-------------------------------------------------
-- OnDisabled: Limpieza al deshabilitar
-------------------------------------------------
function MyModule:OnDisabled()
    -- Guardar estado deshabilitado
    self.db = DB:EnsureDB(self.name, defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- Detener tickers
    BS.Tickers:Stop(self)

    -- Ocultar UI
    if self.frame then
        self.frame:Hide()
    end
end

-------------------------------------------------
-- ApplyOptions: Aplicar cambios de configuración
-------------------------------------------------
function MyModule:ApplyOptions()
    self.db = DB:EnsureDB(self.name, defaults)
    -- Actualizar comportamiento y UI con nueva config
end

-------------------------------------------------
-- Events: Manejadores de eventos
-------------------------------------------------
MyModule.events.PLAYER_LOGIN = function(self)
    -- Código
end
```

### Propiedades del Módulo

| Propiedad | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `name` | string | Sí | Identificador único, debe empezar con `BS_` |
| `label` | string | Sí | Nombre visible en la UI de configuración |
| `enabled` | boolean | No | Estado por defecto (true) |
| `events` | table | No | Table de manejadores de eventos |
| `classes` | string\|nil | No | Filtrar por clase específica ("WARLOCK", etc) |
| `hidden` | boolean | No | Ocultar del panel de configuración |
| `defaults` | table | No | Configuración por defecto |
| `frame` | Frame | No | Frame principal (para movers) |
| `text` | FontString | No | Elemento de texto (para font settings) |

### Métodos del Ciclo de Vida

| Método | Cuándo se llama | Propósito |
|--------|-----------------|-----------|
| `OnInit()` | Al cargar el addon (si habilitado) | Crear UI, registrar eventos, iniciar estado |
| `OnDisabled()` | Al deshabilitar el módulo | Limpiar recursos, detener updates |
| `ApplyOptions()` | Al cambiar configuración | Actualizar módulo con nuevos valores |
| `OnReload()` | Al recargar (si ya fue inicializado) | Re-inicializar sin crear elementos duplicados |

---

## Guía de Creación de Módulos

### Paso 1: Estructura de Archivos

Crea un directorio para tu módulo:

```
Modules/
└── MyModule/
    └── MyModule.lua
```

### Paso 2: Template Básico

Copia y adapta este template:

```lua
-- Modules/MyModule/MyModule.lua
-- @module MyModule
-- @alias MyModule
-- Descripción breve de lo que hace el módulo

local _, BS = ...
local DB     = BS.DB
local API    = BS.API
local Events = BS.Events

local MyModule = {
    name    = "BS_MYMODULE",
    label   = "My Module",
    enabled = true,
    events  = {},
}

API:Register(MyModule)

-------------------------------------------------
-- Defaults
-------------------------------------------------
local defaults = {
    enabled = true,
    -- Agrega tus opciones aquí
}

MyModule.defaults = defaults

-------------------------------------------------
-- OnInit
-------------------------------------------------
function MyModule:OnInit()
    self.db = DB:EnsureDB(self.name, defaults)
    self.enabled = (self.db.enabled ~= false)

    -- Crear UI aquí
    local frame = CreateFrame("Frame", "BS_MyModuleFrame", UIParent)
    frame:SetSize(100, 50)
    self.frame = frame

    -- Registrar con movers si es necesario
    BS.Movers:Register(frame, self.name, self.label)

    -- Registrar eventos
    Events:RegisterEvent("PLAYER_ENTERING_WORLD")

    -- Iniciar ticker si necesita updates periódicos
    -- BS.Tickers:Register(self, 1, function() self:Update() end)
end

-------------------------------------------------
-- OnDisabled
-------------------------------------------------
function MyModule:OnDisabled()
    self.db = DB:EnsureDB(self.name, defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    BS.Tickers:Stop(self)

    if self.frame then
        self.frame:Hide()
    end
end

-------------------------------------------------
-- ApplyOptions
-------------------------------------------------
function MyModule:ApplyOptions()
    self.db = DB:EnsureDB(self.name, defaults)
    -- Actualizar comportamiento
end

-------------------------------------------------
-- Events
-------------------------------------------------
MyModule.events.PLAYER_ENTERING_WORLD = function(self)
    -- Inicialización post-login
end

-------------------------------------------------
-- Funciones internas
-------------------------------------------------
function MyModule:Update()
    -- Lógica de actualización
end
```

### Paso 3: Agregar al TOC

Agrega tu módulo al archivo `BlackSignal.toc`:

```lua
Modules/MyModule/MyModule.lua
```

### Paso 4: Opciones de Configuración (Opcional)

Si tu módulo necesita opciones configurables, debes editar `Core/Config/RightPanel.lua` para agregar las opciones correspondientes.

---

## Eventos Disponibles

### Eventos de Jugador

| Evento | Descripción | Parámetros |
|--------|-------------|------------|
| `PLAYER_LOGIN` | Jugador entra al mundo | - |
| `PLAYER_ENTERING_WORLD` | Al zoning/login | - |
| `PLAYER_REGEN_DISABLED` | Entra en combate | - |
| `PLAYER_REGEN_ENABLED` | Sale de combate | - |
| `PLAYER_SPECIALIZATION_CHANGED` | Cambio de spec | unit |
| `ZONE_CHANGED_NEW_AREA` | Cambio de zona | - |
| `GROUP_ROSTER_UPDATE` | Cambio en grupo | - |

### Eventos de Hechizos/Casteo

| Evento | Descripción | Parámetros |
|--------|-------------|------------|
| `UNIT_SPELLCAST_START` | Inicio de cast | unit, spell, rank |
| `UNIT_SPELLCAST_STOP` | Fin de cast (completo) | unit, spell, rank |
| `UNIT_SPELLCAST_FAILED` | Cast fallido | unit, spell, rank |
| `UNIT_SPELLCAST_INTERRUPTED` | Cast interrumpido | unit, spell, rank |
| `UNIT_SPELLCAST_CHANNEL_START` | Inicio de canalizado | unit, spell, rank |
| `UNIT_SPELLCAST_CHANNEL_STOP` | Fin de canalizado | unit, spell, rank |
| `SPELL_UPDATE_COOLDOWN` | Update de CDs | - |

### Eventos de Aura/Buffs

| Evento | Descripción | Parámetros |
|--------|-------------|------------|
| `UNIT_AURA` | Cambio de buffs/debuffs | unit |

### Eventos de Combate

| Evento | Descripción | Parámetros |
|--------|-------------|------------|
| `PLAYER_TARGET_CHANGED` | Cambio de target | - |
| `UNIT_TARGETABLE_CHANGED` | Unit targetable | unit |

---

## Controles UI Personalizados

### CheckButton con Info Text

El sistema `CheckButton` permite crear checkboxes con texto de información adicional:

```lua
local cb = BS.CheckButton:Create(
    name,           -- Nombre del frame
    parent,         -- Frame padre
    nil,            --
    height,         -- Altura
    labelText,      -- Texto principal
    infoText,       -- Texto de info (opcional)
    point,          -- Punto de anclaje ("TOP", etc)
    relativeTo,     -- Frame relativo
    relativePoint,  -- Punto relativo
    xOfs,           -- Offset X
    yOfs,           -- Offset Y
    {               -- Opciones adicionales
        size = 14,      -- Tamaño del checkbox
        gap = 8,        -- Espacio entre checkbox y texto
        infoGap = 12,   -- Espacio entre texto e info
    }
)

-- Actualizar textos
BS.CheckButton:SetTexts(cb, "Nuevo Label", "Nueva Info")
```

### Colores del Tema

Colores definidos en `Core/UI/Colors.lua`:

```lua
BS.Colors = {
    Brand = {
        purple = {127/255, 63/255, 191/255}, -- Color principal
    },
    Button = {
        normal = {0.15, 0.15, 0.15, 1},
        hover = {0.20, 0.20, 0.20, 1},
        active = {0.12, 0.12, 0.12, 1},
        borderNormal = {0.25, 0.25, 0.25, 1},
        borderHover = {127/255, 63/255, 191/255, 1},
    },
    Text = {
        normal = {1, 1, 1, 1},
        white = {1, 1, 1, 1},
        muted = {0.70, 0.70, 0.70, 1},
    },
    CheckButton = {
        boxBg = {0.12, 0.12, 0.12, 1},
        boxBorder = {0, 0, 0, 1},
        mark = {1, 1, 1, 1},
    },
    Movers = {
        active = {0.12, 0.12, 0.12, 1},
    },
}
```

---

## Convenciones de Código

### Nomenclatura

**Nombres de módulo:**
- Prefijo: `BS_` (BlackSignal)
- Sufijo: Abreviatura descriptiva
- Ejemplos: `BS_CR` (Cursor Ring), `BS_CT` (Combat Time), `BS_BT` (Buff Tracker)

**Nombres de archivos:**
- PascalCase para módulos: `MyModule.lua`
- camelCase para funciones internas

**Nombres de frames:**
- Prefijo: `BS_`
- Formato: `BS_[ModuleName]_[Component]`
- Ejemplos: `BS_MouseRingHolder`, `BS_CombatTimeDisplay`

**Nombres de eventos:**
- Usar nombres de eventos de Blizzard
- No inventar nuevos eventos a menos que sea necesario

### Comentarios

```lua
-- Comentario de una línea

-------------------------------------------------
-- Separador de secciones
-------------------------------------------------

--- Comentario de documentación (para LDoc)
-- @param x descripción
-- @return descripción
```

### Orden en Archivos

1. Headers y documentación
2. Imports/dependencias
3. Declaración del módulo
4. Registro en API
5. Constantes/locals
6. Defaults (configuración)
7. Funciones helper (locales)
8. Funciones públicas
9. Event handlers
10. Ciclo de vida (OnInit, OnDisabled, ApplyOptions)

---

## Módulos Existentes

### MouseRing (BS_CR)

**Descripción:** Tres anillos concéntricos alrededor del cursor
- Anillo decorativo (interno)
- Spinner de GCD (medio)
- Spinner de casteo (externo)

**Eventos usados:**
- `PLAYER_ENTERING_WORLD`
- `SPELL_UPDATE_COOLDOWN`
- `UNIT_SPELLCAST_START/STOP/FAILED/INTERRUPTED`
- `UNIT_SPELLCAST_CHANNEL_START/STOP`

**Propiedades importantes:**
- Actualización de posición en `OnUpdate`
- Usa CooldownFrameTemplate con texturas personalizadas
- Soporte para reverse swipe

### CombatTime (BS_CT)

**Descripción:** Temporizador de combate

**Eventos usados:**
- `PLAYER_REGEN_DISABLED` (entra combate)
- `PLAYER_REGEN_ENABLED` (sale combate)
- `PLAYER_ENTERING_WORLD`

**Características:**
- Usa Tickers para actualizaciones periódicas
- Persiste tiempo total en DB
- Formato mm:ss

### BuffTracker (BS_BT)

**Descripción:** Seguimiento de buffs del raid

**Archivos:**
- `BuffTracker.lua` - Módulo principal
- `Data.lua` - Datos de buffs por clase
- `Engine.lua` - Lógica de construcción de vista
- `UI.lua` - Renderizado de iconos

**Eventos usados:**
- `UNIT_AURA` (solo player)
- `GROUP_ROSTER_UPDATE`
- `ZONE_CHANGED_NEW_AREA`
- `CHALLENGE_MODE_START/RESET/COMPLETED`
- `PLAYER_REGEN_DISABLED/ENABLED`
- `READY_CHECK`

**Características:**
- Se oculta en combate y Mythic+
- Soporta múltiples categorías
- Sistema de throttling para updates

### AutoQueue (BS_AQ)

**Descripción:** Auto-acceptar colas

**Comando slash:** `/bs aq [toggle|on|off]`

### Shimmer (BS_SHIMMER)

**Descripción:** Efectos visuales de clase

**Características:**
- Efectos específicos por clase
- Integración con recursos de clase

### FocusCastTracker (BS_FCT)

**Descripción:** Seguimiento de casteo del focus

**Características:**
- Barra de casteo del focus
- Interrupciones

### EnemyCastList (BS_ECL)

**Descripción:** Lista de casteo de enemigos

### TeleportButtons (BS_TB)

**Descripción:** Botones de teletransporte

---

## Comandos Slash

- `/bs` - Abrir configuración
- `/bs config` - Abrir configuración (alias)
- `/bs aq` o `/bs autoqueue` - Controlar AutoQueue
- `/bs movers` - Modo posicionamiento

---

## Debugging y Troubleshooting

### Verificar que un módulo se registró correctamente:

```lua
/dump BS.API.modules
```

### Verificar configuración de un módulo:

```lua
/dump BS.API.modules.BS_NOMBRE_MODULO
```

### Verificar base de datos:

```lua
/dump BlackSignalDB
```

### Probar movers:

```
/bs movers unlock  -- Activar modo
/bs movers lock    -- Desactivar modo
/bs movers reset   -- Resetear posiciones
```

---

## Notas Importantes para el Desarrollo

1. **Siempre usar `BS.DB:EnsureDB()`** para acceder a la configuración
2. **No crear frames duplicados** - Verificar `self.__initialized` o existencia previa
3. **Limpiar recursos en `OnDisabled()`** - Detener tickers, ocultar UI
4. **Usar `BS.Tickers` en lugar de `OnUpdate`** cuando sea posible
5. **Registrar events correctamente** - Usar `RegisterUnitEvent` para eventos de unidad
6. **No llamar funciones de Blizzard en combate** que puedan causar taints
7. **Usar nombres únicos** para frames (prefijo `BS_`)
8. **Throttlear updates** cuando se disparen muchos eventos (como `UNIT_AURA`)

---

## Próximos Pasos

Para agregar una nueva funcionalidad:

1. Decide si es un módulo nuevo o una mejora a uno existente
2. Crea la estructura de archivos según el patrón
3. Implementa los métodos del ciclo de vida
4. Registra los eventos necesarios
5. Agrega opciones de configuración si es requerido
6. Actualiza el `.toc` si es un módulo nuevo
7. Prueba exhaustivamente

---

## Referencias

### Documentación de API

- [WoW Programming Wiki](https://wow.gamepedia.com/Programming_API_references)
- [WoW API Documentation](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [Blizzard API Documentation (Live FrameXML)](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentation)
- [The War Within API Changes](https://www.wowinterface.com/forums/showthread.php?t=595998)

### Políticas y Directrices

- [Blizzard UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534)

---

*Última actualización: 2024*
