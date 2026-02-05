# BlackSignal - Guía de Creación de Módulos (Ace3 + XML)

Esta guía explica cómo crear nuevos módulos para BlackSignal utilizando el framework Ace3 con sistema de carga basado en archivos XML (siguiendo el patrón de ItruliaQoL).

---

## Tabla de Contenidos

1. [Sistema de Carga XML](#sistema-de-carga-xml)
2. [Arquitectura del Framework](#arquitectura-del-framework)
3. [Librerías Ace3 Disponibles](#librerías-ace3-disponibles)
4. [Estructura de un Módulo](#estructura-de-un-módulo)
5. [Ciclo de Vida de un Módulo (Ace3)](#ciclo-de-vida-de-un-módulo-ace3)
6. [Sistemas Core](#sistemas-core)
7. [Ejemplos de Módulos](#ejemplos-de-módulos)
8. [Buenas Prácticas](#buenas-prácticas)

---

## Sistema de Carga XML

BlackSignal utiliza un sistema de carga basado en archivos XML (similar a ItruliaQoL) en lugar de cargar archivos Lua directamente desde el `.toc`.

### Estructura de Archivos

```
BlackSignal/
├── BlackSignal.toc          # Solo referencia archivos .xml
├── embeds.xml               # Carga todas las librerías Ace3
├── Core/
│   ├── Core.xml            # Carga Init.lua, DB.lua, etc.
│   ├── UI/UI.xml           # Carga Colors.lua
│   ├── Controls/Controls.xml # Carga Button.lua, etc.
│   ├── Utils.xml           # Carga Utils.lua
│   ├── UI/UIFiles.xml      # Carga UI.lua
│   └── Config/Config.xml   # Carga configuración
└── Modules/
    ├── CombatTime/CombatTime.xml
    ├── AutoQueue/AutoQueue.xml
    ├── Shimmer/Shimmer.xml
    └── TuModulo/TuModulo.xml  # Tu nuevo módulo aquí
```

### BlackSignal.toc

El archivo `.toc` ahora solo contiene referencias a archivos `.xml`:

```toc
## Title: |cff7f3fbfBlackSignal|r
## Notes: User Quality of Life Improvements
## Interface: 120000, 120001
## SavedVariables: BlackSignalDB

embeds.xml

Core/UI/UI.xml
Core/Controls/Controls.xml
Core/Utils.xml
Core/Core.xml
Core/UI/UIFiles.xml
Core/Config/Config.xml

Modules/CombatTime/CombatTime.xml
Modules/AutoQueue/AutoQueue.xml
-- ... más módulos ...
Modules/TuModulo/TuModulo.xml
```

### Archivo XML del Módulo

Cada módulo necesita su propio archivo `.xml`:

```xml
<!-- Modules/TuModulo/TuModulo.xml -->
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="TuModulo.lua"/>
</Ui>
```

Para módulos con múltiples archivos:

```xml
<!-- Modules/TuModulo/TuModulo.xml -->
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="TuModuloData.lua"/>
    <Script file="TuModuloEngine.lua"/>
    <Script file="TuModuloUI.lua"/>
    <Script file="TuModulo.lua"/>
</Ui>
```

**Orden de carga importante**: Los archivos se cargan en el orden especificado, así que dependencies deben cargarse antes.

---

## Arquitectura del Framework

BlackSignal utiliza un arquitectura híbrida que combina:

- **Ace3 Framework**: Proporciona la infraestructura base del addon
- **API Personalizada**: Sistema de registro y gestión de módulos
- **Sistemas de Compatibilidad**: Capas que mantienen la API original mientras usan Ace3 internamente

```
┌─────────────────────────────────────────────────────────────┐
│                    BlackSignal (BS)                         │
├─────────────────────────────────────────────────────────────┤
│  Ace3 Framework (Capa Inferior)                             │
│  ├── AceAddon-3.0  (Gestión de addons/módulos)             │
│  ├── AceDB-3.0      (Persistencia con perfiles)             │
│  ├── AceEvent-3.0   (Sistema de eventos)                   │
│  ├── AceTimer-3.0   (Timers y tickers)                      │
│  ├── AceConsole-3.0 (Comandos slash)                        │
│  └── AceConfig-3.0 (Configuración avanzada - opcional)      │
├─────────────────────────────────────────────────────────────┤
│  BlackSignal Core (Capa de Compatibilidad)                  │
│  ├── API (Registro de módulos)                              │
│  ├── DB (EnsureDB, MinimapDB, Profile API)                  │
│  ├── Events (Dispatch con filtros por unidad)               │
│  ├── Tickers (Timers simples para módulos)                  │
│  ├── Movers (Posicionamiento UI)                            │
│  └── Utils (Funciones auxiliares)                           │
├─────────────────────────────────────────────────────────────┤
│  UI Personalizada (Capa Visual)                             │
│  ├── MainPanel, LeftPanel, RightPanel                       │
│  ├── Controles (Button, CheckButton, EditBox, ColorPicker)  │
│  └── Tema púrpura BS (127, 63, 191)                        │
├─────────────────────────────────────────────────────────────┤
│  Modules (Tu código va aquí)                                │
│  └── TuModulo/                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Librerías Ace3 Disponibles

### Librerías Principales (Integradas)

| Librería | Uso en BlackSignal | Cómo Acceder |
|----------|-------------------|--------------|
| **AceAddon-3.0** | Estructura principal del addon | `BS.Addon` |
| **AceDB-3.0** | Sistema de base de datos con perfiles | `BS.DB:GetDB()` |
| **AceEvent-3.0** | Sistema de eventos (opcional) | `BS.Addon:RegisterEvent()` |
| **AceTimer-3.0** | Timers y tickers | `BS.Tickers` (wrapper) |
| **AceConsole-3.0** | Comandos slash (opcional) | `BS.Addon:RegisterChatCommand()` |

### Librerías Adicionales (Disponibles para uso directo)

| Librería | Propósito |
|----------|-----------|
| **AceConfig-3.0** | Crear interfaces de configuración estándar |
| **AceGUI-3.0** | Widgets UI estándar de Ace3 |
| **AceHook-3.0** | Secure hooking de funciones |
| **AceLocale-3.0** | Sistema de localización |
| **AceComm-3.0** | Comunicación entre addons |
| **AceSerializer-3.0** | Serialización de datos |

---

## Estructura de un Módulo

### Ubicación

Crea tu módulo en:

```
BlackSignal/Modules/TuModulo/TuModulo.lua
BlackSignal/Modules/TuModulo/TuModulo.xml
```

### 1. Crear el Archivo XML

```xml
<!-- Modules/TuModulo/TuModulo.xml -->
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="TuModulo.lua"/>
</Ui>
```

### 2. Template Básico del Módulo (Ace3 Directo)

```lua
-- Modules/TuModulo/TuModulo.lua
-- @module TuModulo
-- @alias TuModulo
-- Descripción breve de lo que hace el módulo

local _, BS = ...

-------------------------------------------------
-- Crear como Módulo Ace3
-------------------------------------------------
local TuModulo = BS.Addon:NewModule("TuModulo", "AceEvent-3.0", "AceTimer-3.0")

-------------------------------------------------
-- Metadata (para compatibilidad con BS.API)
-------------------------------------------------
TuModulo.name = "BS_TUMODULO"
TuModulo.label = "Tu Módulo"
TuModulo.enabled = true
TuModulo.defaults = {
    enabled = true,
    x = 0,
    y = 0,
    -- Agrega tus opciones específicas aquí
}

-------------------------------------------------
-- Registrar con BS.API (para panel de configuración)
-------------------------------------------------
BS.API:Register(TuModulo)

-------------------------------------------------
-- Ciclo de Vida de Ace3: OnInitialize
-------------------------------------------------
function TuModulo:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

-------------------------------------------------
-- Ciclo de Vida de Ace3: OnEnable
-------------------------------------------------
function TuModulo:OnEnable()
    self:OnInitialize()

    -- Crear UI si es necesario
    self:CreateUI()

    -- Registrar con sistema de movers si tiene UI movible
    if self.frame and BS.Movers then
        BS.Movers:Register(self.frame, self.name, self.label)
    end

    -- Registrar eventos usando AceEvent
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")

    -- Iniciar timer si necesita actualizaciones periódicas
    -- self:ScheduleRepeatingTimer(1, function() self:Update() end)

    -- Actualizar inicial
    self:Update()
end

-------------------------------------------------
-- Ciclo de Vida de Ace3: OnDisable
-------------------------------------------------
function TuModulo:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- Ocultar UI
    if self.frame then
        self.frame:Hide()
    end

    -- AceEvent automatically unregisters all events
end

-------------------------------------------------
-- ApplyOptions (para panel de configuración)
-------------------------------------------------
function TuModulo:ApplyOptions()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)

    -- Actualizar comportamiento y UI con nueva config
    if self.frame then
        self.frame:SetShown(self.enabled)
    end

    self:Update()
end

-------------------------------------------------
-- Event Handlers (AceEvent style)
-------------------------------------------------
function TuModulo:OnPlayerEnteringWorld()
    if not self.db or self.db.enabled == false then return end
    self:Update()
end

-------------------------------------------------
-- Funciones Internas
-------------------------------------------------
function TuModulo:CreateUI()
    if self.frame then return end

    -- Crear el frame principal si es necesario
    local frame = CreateFrame("Frame", "BS_TuModuloFrame", UIParent)
    frame:SetSize(100, 50)
    frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x or 0, self.db.y or -120)
    frame:SetFrameStrata("LOW")
    frame:Hide()

    -- Crear elemento de texto si es necesario
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    text:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetText("Tu Módulo")

    self.frame = frame
    self.text = text
end

function TuModulo:Update()
    if not self.db or self.db.enabled == false then return end
    if not self.frame then return end

    -- Lógica de actualización del módulo
    self.frame:Show()
end
```

---

## Ciclo de Vida de un Módulo (Ace3)

### 1. Registro con BS.API

```lua
BS.API:Register(TuModulo)
```

El módulo se registra en el sistema `BS.API` para aparecer en el panel de configuración.

### 2. Creación del Módulo Ace3

```lua
local TuModulo = BS.Addon:NewModule("TuModulo", "AceEvent-3.0", "AceTimer-3.0")
```

Los mixins disponibles son:
- Sin mixins: Módulo simple
- `"AceEvent-3.0"`: Manejo de eventos
- `"AceTimer-3.0"`: Timers y tickers
- `"AceConsole-3.0"`: Comandos slash
- Combina múltiples: `"AceEvent-3.0", "AceTimer-3.0"`

### 3. OnInitialize

Llamado automáticamente por Ace3 cuando el addon se carga:

```lua
function TuModulo:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end
```

**Propósito**: Inicializar datos y configuración, pero NO registrar eventos ni crear UI aún.

### 4. OnEnable

Llamado después de OnInitialize y cada vez que el módulo se habilita:

```lua
function TuModulo:OnEnable()
    self:OnInitialize()  -- Recargar configuración

    -- Crear UI
    self:CreateUI()

    -- Registrar eventos
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")

    -- Iniciar timers
    self:ScheduleRepeatingTimer(1, function() self:Update() end)

    -- Actualizar
    self:Update()
end
```

**Propósito**: Configurar el módulo activo (UI, eventos, timers).

### 5. OnDisable

Llamado cuando el módulo se deshabilita:

```lua
function TuModulo:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- Ocultar UI
    if self.frame then
        self.frame:Hide()
    end

    -- AceEvent automatically unregisters all events
    -- AceTimer timers are NOT automatically cancelled
end
```

**IMPORTANTE**: Los timers de AceTimer NO se cancelan automáticamente. Debes hacerlo manualmente si es necesario.

### 6. ApplyOptions

Llamado cuando el usuario cambia opciones en el panel de configuración:

```lua
function TuModulo:ApplyOptions()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    -- Actualizar comportamiento y UI
    self:Update()
end
```

### 7. Event Handlers (AceEvent)

Con AceEvent, los manejadores son métodos del módulo:

```lua
function TuModulo:OnPlayerEnteringWorld()
    self:Update()
end

function TuModulo:OnUnitAura(unit)
    if unit ~= "player" then return end
    self:Update()
end
```

Registro de eventos en OnEnable:

```lua
-- Evento normal
self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")

-- Evento de unidad con filtro
self:RegisterUnitEvent("UNIT_AURA", "player", "OnUnitAura")
```

---

## Sistemas Core

### Base de Datos (AceDB-3.0)

BlackSignal usa AceDB internamente pero mantiene la API `EnsureDB`:

```lua
-- Obtener la DB del módulo con defaults
local db = BS.DB:EnsureDB(self.name, defaults)

-- API de Perfiles (NUEVO - usando AceDB)
local currentProfile = BS.DB:GetCurrentProfile()
BS.DB:SetProfile("MyProfile")
local profiles = BS.DB:GetProfiles()
BS.DB:CopyProfile("Profile1", "Profile2")
BS.DB:ResetProfile()
BS.DB:DeleteProfile("OldProfile")

-- Obtener el objeto AceDB directo (uso avanzado)
local aceDB = BS.DB:GetDB()
aceDB.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
```

### Sistema de Eventos

```lua
-- Registrar evento normal
Events:RegisterEvent("PLAYER_LOGIN")

-- Registrar evento de unidad con filtro
Events:RegisterUnitEvent("UNIT_AURA", "player")

-- Manejador en el módulo
TuModulo.events.PLAYER_LOGIN = function(self)
    -- Código
end

-- USO DIRECTO DE AceEvent (opcional)
-- AceEvent está embedded en BS.Addon
BS.Addon:RegisterEvent("EVENT_NAME", "CallbackMethod")
function TuModulo:CallbackMethod(event, ...)
    -- Código
end
```

### Sistema de Tickers (AceTimer-3.0)

```lua
-- API de compatibilidad (usa AceTimer internamente)
Tickers:Register(self, 1, function()
    self:Update()
end)

Tickers:Stop(self)

-- Nuevas funciones usando AceTimer directamente
local handle = Tickers:ScheduleOnce(5, function()
    print("5 segundos pasaron")
end)

local repeating = Tickers:ScheduleRepeating(1, self.Update, self)
Tickers:Cancel(repeating)

-- USO DIRECTO DE AceTimer (opcional)
local timer = BS.Addon:ScheduleRepeatingTimer(1, "Update", self)
BS.Addon:CancelTimer(timer)
```

### Sistema de Movers

```lua
-- Registrar frame como movible
BS.Movers:Register(frame, self.name, self.label)

-- Tu módulo necesita x/y en defaults
local defaults = {
    x = 0,
    y = -120,
}

-- Aplicar posición (automático desde el sistema)
-- Manual si necesitas:
BS.Movers:Apply(self.name)

-- Comandos slash (disponibles para el usuario)
-- /bs movers toggle
-- /bs movers on
-- /bs movers off
-- /bs movers reset
```

---

## Ejemplos de Módulos (Ace3)

### Módulo Simple (Sin UI)

```lua
-- Modules/SimpleModule/SimpleModule.xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="SimpleModule.lua"/>
</Ui>
```

```lua
-- Modules/SimpleModule/SimpleModule.lua
local _, BS = ...

local SimpleModule = BS.Addon:NewModule("SimpleModule", "AceEvent-3.0")

SimpleModule.name = "BS_SIMPLE"
SimpleModule.label = "Módulo Simple"
SimpleModule.enabled = true
SimpleModule.defaults = {
    enabled = true,
    counter = 0,
}

BS.API:Register(SimpleModule)

function SimpleModule:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

function SimpleModule:OnEnable()
    self:OnInitialize()
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
end

function SimpleModule:OnPlayerLogin()
    print("Módulo Simple cargado! Contador: " .. self.db.counter)
end
```

### Módulo con UI y Texto

```lua
-- Modules/TextModule/TextModule.xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="TextModule.lua"/>
</Ui>
```

```lua
-- Modules/TextModule/TextModule.lua
local _, BS = ...

local TextModule = BS.Addon:NewModule("TextModule", "AceEvent-3.0")

TextModule.name = "BS_TEXT"
TextModule.label = "Módulo de Texto"
TextModule.enabled = true
TextModule.defaults = {
    enabled = true,
    x = 0,
    y = -200,
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 24,
    fontFlags = "OUTLINE",
    text = "Hola Mundo",
}

BS.API:Register(TextModule)

function TextModule:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

function TextModule:OnEnable()
    self:OnInitialize()
    self:CreateUI()

    if self.frame and BS.Movers then
        BS.Movers:Register(self.frame, self.name, self.label)
    end

    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
end

function TextModule:CreateUI()
    if self.frame then return end

    local frame = CreateFrame("Frame", "BS_TextModuleFrame", UIParent)
    frame:SetSize(200, 50)
    frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x, self.db.y)
    frame:Hide()

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    text:SetFont(self.db.font, self.db.fontSize, self.db.fontFlags)
    text:SetTextColor(1, 1, 1, 1)
    text:SetText(self.db.text)

    self.frame = frame
    self.text = text
end

function TextModule:OnPlayerEnteringWorld()
    if self.frame then
        self.frame:SetShown(self.enabled)
    end
end

function TextModule:ApplyOptions()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)

    if self.text then
        self.text:SetFont(self.db.font, self.db.fontSize, self.db.fontFlags)
        self.text:SetText(self.db.text)
    end
end

function TextModule:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    if self.frame then
        self.frame:Hide()
    end
end
```

### Módulo con Ticker Periódico

```lua
-- Modules/TimerModule/TimerModule.xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="TimerModule.lua"/>
</Ui>
```

```lua
-- Modules/TimerModule/TimerModule.lua
local _, BS = ...

local TimerModule = BS.Addon:NewModule("TimerModule", "AceTimer-3.0")

TimerModule.name = "BS_TIMER"
TimerModule.label = "Módulo Timer"
TimerModule.enabled = true
TimerModule.defaults = {
    enabled = true,
    updateInterval = 1,
}

BS.API:Register(TimerModule)

function TimerModule:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

function TimerModule:OnEnable()
    self:OnInitialize()
    self:StartTicker()
end

function TimerModule:StartTicker()
    -- Cancelar timer anterior si existe
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
    end

    -- Crear nuevo timer
    self.updateTimer = self:ScheduleRepeatingTimer(self.db.updateInterval, function()
        self:Update()
    end)
end

function TimerModule:Update()
    if not self.db or self.db.enabled == false then return end
    print("Timer tick! " .. date("%H:%M:%S"))
end

function TimerModule:ApplyOptions()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self:StartTicker()
end

function TimerModule:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- IMPORTANTE: Cancelar timers manualmente
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end
end
```

### Módulo con AceEvent (Combate)

```lua
-- Modules/CombatModule/CombatModule.xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="CombatModule.lua"/>
</Ui>
```

```lua
-- Modules/CombatModule/CombatModule.lua
local _, BS = ...

local CombatModule = BS.Addon:NewModule("CombatModule", "AceEvent-3.0")

CombatModule.name = "BS_COMBAT"
CombatModule.label = "Combat Module"
CombatModule.enabled = true
CombatModule.defaults = {
    enabled = true,
    showMessage = true,
}

BS.API:Register(CombatModule)

function CombatModule:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
    self.inCombat = false
end

function CombatModule:OnEnable()
    self:OnInitialize()

    -- Registrar eventos de combate
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEnterCombat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnLeaveCombat")
end

function CombatModule:OnEnterCombat()
    self.inCombat = true
    if self.db.showMessage then
        print("¡Entrando en combate!")
    end
end

function CombatModule:OnLeaveCombat()
    self.inCombat = false
    if self.db.showMessage then
        print("¡Saliendo de combate!")
    end
end

function CombatModule:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    self.inCombat = false
end
```

---

## Buenas Prácticas

### 1. Sistema de Carga XML

- **SIEMPRE crear archivo .xml** para cada módulo
- **Agregar el .xml al .toc**, no el .lua
- **Orden de carga importante**: Dependencies antes que dependientes

```xml
<!-- Modules/TuModulo/TuModulo.xml -->
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="TuModuloData.lua"/>   <!-- Primero: datos -->
    <Script file="TuModulo.lua"/>        <!-- Después: lógica -->
</Ui>
```

### 2. Nomenclatura

- **Nombre del módulo**: `BS_NOMBRE_MODULO` (prefijo BS_)
- **Nombre del archivo**: `ModuleName.lua` (PascalCase)
- **Nombre del frame**: `BS_ModuleName_Component`
- **Funciones**: `camelCase`
- **Event handlers Ace3**: `OnEventName` (prefijo On)

### 3. Estructura de Archivos (Ace3)

```lua
-- 1. Header y documentación
-- @module ModuleName
-- @alias ModuleName

-- 2. Imports
local _, BS = ...

-- 3. Crear módulo Ace3 con mixins
local ModuleName = BS.Addon:NewModule("ModuleName", "AceEvent-3.0", "AceTimer-3.0")

-- 4. Metadata
ModuleName.name = "BS_MODULENAME"
ModuleName.label = "Module Label"
ModuleName.defaults = {...}

-- 5. Registrar con BS.API
BS.API:Register(ModuleName)

-- 6. OnInitialize
function ModuleName:OnInitialize() end

-- 7. OnEnable
function ModuleName:OnEnable() end

-- 8. OnDisable
function ModuleName:OnDisable() end

-- 9. ApplyOptions
function ModuleName:ApplyOptions() end

-- 10. Event handlers (métodos, no tabla)
function ModuleName:OnEventName(...) end

-- 11. Funciones internas
function ModuleName:Update() end
```

### 4. Gestión de Estados

```lua
-- SIEMPRE usar BS.DB:EnsureDB para acceder a la configuración
function ModuleName:Update()
    local db = BS.DB:EnsureDB(self.name, self.defaults)
    if not db or db.enabled == false then return end
    -- ...
end
```

### 5. Evitar Frames Duplicados

```lua
function ModuleName:CreateUI()
    if self.frame then return end  -- Ya existe
    -- Crear frames
    -- ...
end

function ModuleName:OnEnable()
    if self.__initialized then
        self:OnReload()
        return
    end
    self.__initialized = true
    -- ...
end
```

### 6. Limpieza en OnDisable

```lua
function ModuleName:OnDisable()
    -- 1. Actualizar DB
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- 2. Cancelar timers (AceTimer NO lo hace automáticamente)
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    -- 3. Ocultar UI
    if self.frame then
        self.frame:Hide()
    end

    -- NO destruir frames (para preservar posición)
    -- AceEvent automáticamente desregistra eventos
end
```

### 7. Throttlear Updates (AceEvent)

```lua
-- Para eventos que se disparan frecuentemente
local throttle = 0

function ModuleName:OnUnitAura(unit)
    if unit ~= "player" then return end

    local now = GetTime()
    if now - throttle < 0.1 then return end  -- Max 10 updates/sec
    throttle = now

    self:Update()
end

-- Registrar en OnEnable
self:RegisterUnitEvent("UNIT_AURA", "player", "OnUnitAura")
```

### 8. Evitar Taints en Combate

```lua
-- NO crear/modificar frames en combate
function ModuleName:SomeFunction()
    if InCombatLockdown() then
        -- Solo actualizar datos, no UI
        self.dataChanged = true
        return
    end

    -- Safe to modify UI
    self:UpdateUI()
end

-- Registrar evento para actualizar UI al salir de combate
function ModuleName:OnPlayerRegenEnabled()
    if self.dataChanged then
        self:UpdateUI()
        self.dataChanged = false
    end
end

-- En OnEnable
self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
```

### 9. Patrones de AceEvent

```lua
-- Método con nombre específico
self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
function ModuleName:OnPlayerLogin(event, ...)
    -- ...
end

-- Método con mismo nombre que evento
self:RegisterEvent("PLAYER_LOGIN")
function ModuleName:PLAYER_LOGIN(event, ...)
    -- ...
end

-- Evento de unidad
self:RegisterUnitEvent("UNIT_AURA", "player", "OnUnitAura")
function ModuleName:OnUnitAura(event, unit, ...)
    -- ...
end
```

### 10. Patrones de AceTimer

```lua
-- Timer único
local timer = self:ScheduleTimer(5, function()
    print("5 segundos después")
end)

-- Timer repetitivo
local repeating = self:ScheduleRepeatingTimer(1, "UpdateTick")

-- Timer a método con argumentos
self:ScheduleTimer(5, "ShowMessage", "Hola", "Mundo")

-- Cancelar timer
self:CancelTimer(timer)
```

### 11. Debugging

```lua
function ModuleName:Debug(msg, ...)
    if not self.db.debug then return end
    print(string.format("|cff7f3fbf[BS:%s]|r %s", self.label, msg:format(...)))
end

-- Uso
self:Debug("Inicializando módulo con config: %s", self.db.someOption)
```

---

## Uso Avanzado de Ace3

### Callbacks de Cambio de Perfil

```lua
function ModuleName:OnInit()
    self.db = BS.DB:EnsureDB(self.name, defaults)

    -- Registrarse para cambios de perfil
    local aceDB = BS.DB:GetDB()
    aceDB.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    aceDB.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    aceDB.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
end

function ModuleName:OnProfileChanged(event, database)
    -- Recargar configuración cuando cambia el perfil
    self:ApplyOptions()
end
```

### Comandos Slash con AceConsole

```lua
function ModuleName:OnInit()
    -- Registrar comandos slash usando AceConsole
    BS.Addon:RegisterChatCommand("tumodulo", "HandleSlashCommand")

    -- O con la API antigua (más simple)
    -- La configuración de slash está en Core/Config.lua
end

function ModuleName:HandleSlashCommand(input)
    if not input or input:trim() == "" then
        self:Toggle()
        return
    end

    local cmd, rest = input:match("^(%S+)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "toggle" then
        self:Toggle()
    elseif cmd == "enable" then
        self.enabled = true
        self.db.enabled = true
    elseif cmd == "disable" then
        self:OnDisabled()
    end
end
```

### Hooks con AceHook

```lua
local AceHook = LibStub("AceHook-3.0")

function ModuleName:OnInit()
    -- Secure hook de una función de Blizzard
    AceHook:SecureHook("TargetFrame_Update", function(self)
        -- Tu código después de TargetFrame_Update
    end)

    -- O hook embebido en el módulo
    -- AceHook ya está disponible
end
```

---

## Checklist para Crear un Módulo

### Archivos
- [ ] Crear carpeta `Modules/TuModulo/`
- [ ] Crear archivo `Modules/TuModulo/TuModulo.xml`
- [ ] Crear archivo `Modules/TuModulo/TuModulo.lua`

### XML
- [ ] Agregar `<Script file="TuModulo.lua"/>` en el XML
- [ ] Agregar `Modules/TuModulo/TuModulo.xml` al `BlackSignal.toc`

### Código Lua
- [ ] Crear módulo con `BS.Addon:NewModule()` con mixins necesarios
- [ ] Definir `name`, `label`, `enabled`, `defaults`
- [ ] Registrar con `BS.API:Register()`
- [ ] Implementar `OnInitialize()`
- [ ] Implementar `OnEnable()`
- [ ] Implementar `OnDisable()`
- [ ] Implementar `ApplyOptions()`
- [ ] Implementar event handlers como métodos del módulo

### Configuración (Opcional)
- [ ] Agregar opciones en `Core/Config/RightPanel.lua`
- [ ] Agregar handlers de configuración si es necesario

### Testing
- [ ] Probar carga del addon
- [ ] Probar enable/disable del módulo
- [ ] Probar cambio de opciones en el panel de config
- [ ] Probar cambio de perfil (si usa DB)
- [ ] Verificar que no hay errores en `/dump`

### Archivos a Modificar al Crear Módulo

**1. BlackSignal.toc**
```toc
Modules/TuModulo/TuModulo.xml
```

**2. Modules/TuModulo/TuModulo.xml** (nuevo)
```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="TuModulo.lua"/>
</Ui>
```

**3. Modules/TuModulo/TuModulo.lua** (nuevo)
```lua
local _, BS = ...
local TuModulo = BS.Addon:NewModule("TuModulo", "AceEvent-3.0")
-- ... resto del código
```

---

## Recursos Adicionales

### Documentación de Ace3

- [Ace3 Getting Started](https://www.wowace.com/projects/ace3/pages/getting-started)
- [AceDB Tutorial](https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
- [AceConfig Tutorial](https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables)
- [AceGUI Tutorial](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-tutorial)

### Documentación de WoW API

- [WoW Programming Wiki](https://wow.gamepedia.com/Programming_API_references)
- [WoW API Documentation](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [Blizzard API Documentation](https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentation)

---

*Última actualización: 2025 - BlackSignal Ace3 Integration*
