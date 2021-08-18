
# [SourceMod/CS:GO] NoBlock for MG

Yet another NoBlock plugin designed to be used on MG servers (multi games and courses) with zero configuration (i.e., no divergence on cvars). This plugin solves player's collision on moving platforms and grenade projectile collision at the same time.

----

- [[SourceMod/CS:GO] NoBlock for MG](#sourcemodcsgo-noblock-for-mg)
  - [Usage](#usage)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
    - [ConVars](#convars)
    - [ConVars added by this plugin](#convars-added-by-this-plugin)
  - [Comparison](#comparison)
  - [Performance Concerns](#performance-concerns)
  - [Known Issues](#known-issues)
  - [Acknowledgements](#acknowledgements)

## Usage

### Prerequisites

NoBlock for MG depends on the following extensions:

- DHooks2
  - Tested with [peace-maker's DHooks2](https://github.com/peace-maker/DHooks2)
- SendProxy
  - Tested with [SlidyBat's SendProxy](https://github.com/SlidyBat/sendproxy)

### Installation

- Install DHooks2 and SendProxy
- Download plugin files from releases (or compile the plugin source by your own)
- Copy `noblock.smx` to `csgo/addons/sourcemod/plugins`
- Copy `noblock.games.txt` to `csgo/addons/sourcemod/gamedata`

### ConVars

- `mp_solid_teammates`: `any` (Recommended: `1`)
- `cs_enable_player_physics_box`: `any`
- `sv_turbophysics`: `any` (Recommended: `0`)

### ConVars added by this plugin

NOTE: This plugin is designed to be used with zero configuration. In almost 100% of cases, you don't need to touch the following cvars.

- `sm_noblock 1`
  - Enables this noblock feature.
  - Default value is `1`
- `sm_noblock_ignore_projectiles 0`
  - Regardless of this setting, this plugin solves the issue that players get stuck with grenade projectiles and cannot move for a while.
  - By setting this cvar to 0, projectiles are still collideable with players so they can apply damage on hit.
  - By setting this cvar to 1, projectiles become completely non-collideable with players.
  - Default value is `0`

## Comparison

Here is the comparison between traditional noblock plugins and NoBlock for MG.

|  | CollisionGroup | Entity's `ShouldCollide` | NoBlock for MG |
|---|:-:|:-:|:-:|
| Prevents players sticking with each other on moving platforms | ✅ | - | ✅ |
| Avoid stuck and position gets rollbacked by the engine after teleport | ✅ | - | ✅ |
| Prevents players sticking with grenade projectiles | ✅ | - | ✅ |
| Grenade projectiles can hit and damage players | - | ✅ | ✅ |
| Prevents players penetrating to vphys-based world collision (e.g., `func_brush`) | - | ✅ | ✅ |
| Clients can predict them as if players are non-collideable each other | ✅ | ✅ | ✅ |

- **CollisionGroup** method:
  - Sets player's collision group to `COLLISION_GROUP_DEBRIS_TRIGGER`
- **Entity's `ShouldCollide`** method:
  - Overrides player entity's `ShouldCollide` method
  - Fakes player's collision group as `COLLISION_GROUP_DEBRIS_TRIGGER` by using SendProxy
- **NoBlock for MG**:
  - Overrides `CGameRules::ShouldCollide` by using DHook
  - Fakes player's collision group as `COLLISION_GROUP_DEBRIS_TRIGGER` by using SendProxy

## Performance Concerns

Even though `CGameRules::ShouldCollide` gets called gazillion times in extreme scenarios like many non-hibernated vphys-props collide with each other on vphys-based platforms, this plugin should be almost harmless since the rest of the part in collision detection code takes the most of the processing time. If you think this plugin causes huge server lag, try `sm_noblock 0` to temporarily disable the DHook on `CGameRules::ShouldCollide` and see if this plugin is the criminal.

## Known Issues

- Grenade projectiles can stop moving platforms when it collides with player and platform at the same time. For now, use `sm_noblock_ignore_projectiles 1` if you dislike this behavior, and you can forgive projectiles passing through players.
- Players cannot stand on hostages

## Acknowledgements

- The idea to override `ShouldCoillide` and pretend player's CollisionGroup via SendProxy came from [Bakros's NoBlock plugin](https://forums.alliedmods.net/showthread.php?p=1783205). Huge thanks to Bakros.
- Thanks to the contributors of NoBlock, DHooks and SendProxy.