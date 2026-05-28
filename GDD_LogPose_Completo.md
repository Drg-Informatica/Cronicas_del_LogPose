# LOG POSE Chronicles - Game Design Document
### Crónicas del Log Pose: El Despertar del Mar

---

## 1. Resumen Ejecutivo (The Pitch)

- **Concepto principal:** Un roguelike de construcción de mazos donde el jugador asume el rol de un capitán pirata que debe navegar un archipiélago peligroso, reclutar tripulación y combatir enemigos usando cartas que representan habilidades de las "Esencias del Océano". Cada partida es única gracias a la generación procedimental de mapas, encuentros y recompensas.

- **Género:** Roguelike Deckbuilder (construcción de mazos con progresión procedimental)

- **Plataforma:** PC (Windows/Linux), Android, iOS

- **Público objetivo:** Jugadores de estrategia táctica (18-35 años), fans de roguelikes y deckbuilders (Slay the Spire, Balatro), y jugadores móviles que buscan sesiones de 15-30 minutos de alta profundidad estratégica.

---

## 2. Gameplay y Mecánicas

### Mecánicas Core
El jugador el 90% del tiempo:
- **Navega** por un mapa de islas generado proceduralmente eligiendo su ruta
- **Combate** por turnos jugando cartas de su mazo (ataques, defensas, habilidades)
- **Construye su mazo** añadiendo, eliminando o mejorando cartas tras cada encuentro
- **Gestiona su tripulación**, eligiendo qué miembros llevar para diversificar sus Esencias disponibles

### Mecánica Diferencial 1: Marea Dinámica
El estado del entorno (clima, corrientes marinas) se actualiza cada cierto número de turnos durante el combate y modifica:
- El **coste en energía** de ciertas cartas (una tormenta encarece cartas de Furia, potencia las de Deriva)
- La **eficacia** de habilidades específicas (la corriente favorable reduce el coste de cartas de movimiento)
- Esto obliga al jugador a adaptar su estrategia en tiempo real

### Mecánica Diferencial 2: Gestión de Tripulación
- El jugador puede reclutar hasta 4 tripulantes a lo largo de la aventura
- Cada tripulante tiene un **Rol** que determina qué tipo de cartas de Esencia añade al pool disponible del jugador
- Sin un tripulante de un Rol concreto, esas cartas de Esencia no pueden aparecer como recompensa
- Bajo condiciones específicas (combo de cartas, marea concreta), los tripulantes pueden **"despertar"** su habilidad, activando un efecto poderoso temporal

### Roles de Tripulante y Esencias que aportan

| Rol | Esencia | Descripción |
|---|---|---|
| **Corsario** | Furia | Guerrero ofensivo. Aporta cartas de daño directo al mazo |
| **Heraldo** | Coloso | Protector y sanador. Aporta cartas de defensa, escudo y curación |
| **Timonel** | Deriva | Estratega y navegante. Aporta cartas de manipulación, efectos de estado y control |
| **Forjado** | Dominación | Portador de un poder ancestral. Aporta cartas que rompen defensas y dominan enemigos. **Extremadamente raro** |

### Mecánica Diferencial 3: Sistema de Poder
Cada Capitán y cada tripulante posee un **Poder único** (su habilidad especial o don natural) que modifica cómo se comportan las cartas de su Esencia. Dos personajes con la misma Esencia se sienten completamente distintos gracias a su Poder.

**Ejemplos de Poder:**
- *Capitán con Furia + Poder "Impacto":* Sus cartas de Furia tienen un 30% de probabilidad de aturdir al enemigo un turno
- *Capitán con Furia + Poder "Filo":* Sus cartas de Furia acumulan marcas de "Corte" y al llegar a 3 liberan un golpe que ignora todo el bloqueo enemigo
- *Tripulante Timonel + Poder "Lectura del Viento":* Sus cartas de Deriva se potencian o cambian efecto según la Marea activa

### Controles
- **Click izquierdo / Tap:** Seleccionar carta, interactuar con UI
- **Arrastrar y soltar / Drag:** Jugar una carta al campo
- **Click derecho / Mantener presionado:** Ver descripción detallada de carta
- **Tecla E / Botón Fin de Turno:** Terminar turno
- **Tecla ESC / Botón Menú:** Pausa / Menú de opciones

### Game Loop
```
Inicio de run
    → Elegir Capitán (personaje con Esencia y Poder únicos → mazo inicial único)
    → Mapa procedimental generado (archipiélago con 3 biomas)
    → Elegir ruta entre nodos del mapa:
        ├── ⚔️  Combate normal → Recompensa (carta nueva de Esencia disponible, oro)
        ├── 💀  Combate de élite → Recompensa mayor (reliquia) + posible carta de Dominación
        ├── 🏝️  Evento narrativo → Decisión con consecuencias (posible reclutamiento)
        ├── 🏪  Tienda → Comprar/eliminar cartas o reliquias
        ├── 🔥  Fogata → Mejorar una carta o recuperar vida
        └── 💀💀 Jefe de bioma → Recompensa especial + acceso al siguiente bioma
    → Al completar los 3 biomas → Victoria (run completada)
    → Muerte → Reinicio (roguelike: se pierde el progreso de run)
    → Desbloqueo de contenido meta-progresión (nuevas cartas en el pool)
```

---

## 3. Elementos Técnicos

- **Motor de videojuego:** Godot 4.x

- **Lenguaje de programación:** GDScript — lenguaje nativo de Godot, tipado fuerte opcional, diseñado específicamente para videojuegos. Godot 4 también soporta C# (.NET 8) como alternativa.

- **Sistema de Input:** InputMap de Godot (soporte nativo para teclado/ratón y táctil sin plugins adicionales)

- **Físicas:** No se requieren físicas complejas. La lógica del juego se gestiona mediante sistemas de estado (State Machines) y señales (sistema de eventos nativo de Godot). Las cartas se mueven mediante Tween (nodo nativo de Godot 4), no física real.

- **Persistencia de datos:** SQLite para base de datos local de cartas, reliquias y progreso del jugador (via plugin godot-sqlite de la Asset Library)

- **Serialización:** JSON nativo de Godot (clase JSON built-in) para configuraciones del sistema y comunicación con posibles leaderboards online

- **Control de versiones:** Git + Git LFS (Large File Storage) para activos binarios (imágenes, audio)

- **Plugins/Assets Necesarios:**
  - Tween (nativo en Godot 4) para movimiento y animación de cartas
  - Label / RichTextLabel + DynamicFont para tipografía de alta calidad (nativo, sin plugins)
  - AudioStreamPlayer + AudioBus (nativo) para música dinámica según la Marea
  - Control nodes + Theme system de Godot para UI adaptable a pantallas táctiles y de escritorio

---

## 4. Historia y Mundo

### Narrativa
El jugador encarna a un **Capitán Pirata** sin nombre (personalizable) que busca llegar a **"Las Aguas del Fin"** a **"The No-Name"**, un lugar legendario donde se dice que se encuentra el secreto del mar. Para lograrlo, debe cruzar un peligroso archipiélago dividido en tres grandes regiones, cada una dominada por un poderoso Jefe. A lo largo del viaje, reclutará una tripulación única en cada partida y descubrirá fragmentos de una historia más grande.

### Las Esencias del Océano
Son poderes sobrenaturales que ciertos individuos poseen, otorgándoles habilidades extraordinarias. Se clasifican en cuatro tipos:

| Esencia | Tipo de cartas | Mecánica principal | Disponibilidad |
|---|---|---|---|
| ⚡ **Furia** | Ataque / daño directo | Daño agresivo con efectos secundarios | Común |
| 🛡️ **Coloso** | Defensa / escudo / curación | Absorción de daño y recuperación | Común |
| 🌊 **Deriva** | Manipulación / control | Robar cartas, reducir costes, efectos de estado | Media |
| 👑 **Dominación** | Voluntad / ruptura | Ignora bloqueo, escala con daño recibido, suprime habilidades enemigas | **Muy rara** |

### La Esencia del Dominación — Reglas especiales
El Dominación es la Esencia más poderosa y escasa del mundo. Solo los individuos con una voluntad extraordinaria pueden portarla:
- Sus cartas **nunca aparecen en recompensas de combate normal**
- Solo se obtienen derrotando **combates de élite o jefes de bioma**
- En la tienda cuestan **el doble de oro** que cualquier otra carta
- Solo se pueden tener un **máximo de 5 cartas de Dominación** en el mazo simultáneamente
- Reclutar a un tripulante **Forjado** es la única forma de que aparezcan en el pool de recompensas

### El Sistema de Poder
Cada Capitán y tripulante posee un **Poder** que define su identidad única. El Poder no es un tipo de carta sino un **modificador permanente** que altera el comportamiento de las cartas de su Esencia. Esto garantiza que dos personajes con la misma Esencia ofrezcan experiencias de juego completamente distintas.

### Los 3 Biomas (Actos)
| Acto | Nombre | Ambientación | Jefe Final |
|---|---|---|---|
| 1 | Mar de la Calma | Archipiélago tropical, enemigos piratas comunes | Corsario de la Corona |
| 2 | Las Aguas Grises | Zona de niebla, criaturas marinas, clima hostil | El Kraken Encadenado |
| 3 | El Abismo Final | Fondo marino sobrenatural, guardianes ancestrales | El Guardián de las Aguas del Fin |

### Estilo Visual
- **Arte 2D de alta fidelidad** con animaciones fluidas (NO pixel art)
- Estética de ilustración náutica estilizada, colores saturados y vibrantes
- Las cartas tienen ilustraciones tipo "grabado antiguo modernizado"
- La UI tiene estética de mapas náuticos y brújulas

### Audio
- **Música:** Orquestal con instrumentos náuticos (acordeón, cuerdas, percusión) que cambia dinámicamente según la Marea activa durante el combate
- **SFX:** Sonidos de agua, viento, madera crujiendo, impactos de combate marinero
- **Música de bioma:** Cada zona tiene su propia identidad musical (tropical → melancólica/niebla → épica/abismo)

---

## 5. Interfaz de Usuario (UI/UX)

### Menú Principal
- **Jugar** (Nueva run / Continuar run guardada)
- **Colección** (Ver todas las cartas y reliquias desbloqueadas)
- **Opciones** (Audio, Gráficos, Controles, Idioma)
- **Créditos**
- **Salir**

### HUD durante el Combate
- **Mano de cartas** (zona inferior) — cartas jugables arrastrándolas al campo
- **Energía actual / Energía máxima** (ej: 3/3 por turno)
- **Puntos de vida del Capitán** — barra de vida + número
- **Puntos de vida del Enemigo** — barra de vida + número + intención del siguiente movimiento
- **Indicador de Marea Dinámica** — icono de clima con contador de turnos hasta el cambio
- **Iconos de Tripulación** — Rol, estado de cada tripulante y si su habilidad está activa/despertada
- **Mazo restante** (número de cartas) y **Pila de descarte** (número de cartas)
- **Botón "Fin de Turno"**

### HUD durante el Mapa
- **Mapa de islas** con nodos y rutas disponibles
- **Salud actual** del capitán
- **Reliquias equipadas**
- **Oro disponible**
- **Mazo actual** (accesible en cualquier momento)

### Navegación de Menús
- Transiciones animadas con efecto de "olas" o "desplazamiento de mapa náutico"
- Diseño táctil-first: botones grandes, sin hover exclusivo de ratón
- Todas las pantallas accesibles desde el mapa con un solo toque/clic

---

## 6. Progresión y Niveles

### Estructura
**Mapa procedimental** generado al inicio de cada run:
- Cada run genera un archipiélago único con nodos distribuidos en 3 biomas
- El jugador elige su camino entre nodos, no hay un orden fijo
- Los nodos tienen tipos aleatorios pero con distribución balanceada (no puede haber 5 tiendas seguidas)

### Curva de Dificultad
| Fase | Descripción |
|---|---|
| **Bioma 1 (Acto 1)** | Introducción de mecánicas básicas. Enemigos con patrones simples. Se presentan Furia y Coloso. La Esencia de Deriva aparece de forma limitada. |
| **Bioma 2 (Acto 2)** | Aparecen efectos de estado (veneno, parálisis, congelación) y la Marea Dinámica se vuelve más impactante. Primera aparición posible de cartas de Dominación en élites. |
| **Bioma 3 (Acto 3)** | Total expresión de sinergias entre Esencias. Los enemigos usan contramedidas a estrategias obvias. El Jefe Final tiene fases y puede usar Dominación. |
| **Post-game (Ascensiones)** | Sistema de modificadores de dificultad desbloqueables (equivalente a Ascensiones de StS) para runs adicionales más difíciles. |

### Meta-progresión
- Completar runs desbloquea nuevas cartas que pueden aparecer en futuras partidas
- Los Capitanes se desbloquean cumpliendo condiciones específicas
- Los tripulantes disponibles para reclutar se amplían con el progreso global
- Los relatos narrativos de los eventos se expanden con más opciones según el progreso global

---

*GDD Version 1.2 — Raftel Digital Studios*
*Motor de videojuego: Godot 4.x*
