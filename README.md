# dvr-power-spells - Spell Modules for dvr_power

58 spell modules for the [dvr_power](https://github.com/DeVerino-DVR/dvr-power) magic system on FiveM.

> Originally developed for the VLight RP event.

## Important Notice

This script is **complex**. It was specifically designed for a custom FiveM server environment. If you are not experienced with FiveM development or adapting advanced systems, it will be very difficult to install or modify correctly.

**No support will be provided. There will be no help, assistance, or custom adaptation. The system is given as-is.**

If you use it, you must know what you are doing.

## Credits

These scripts are distributed for free. Credits must remain attributed to:
- **[DVR](https://github.com/DeVerino-DVR)** (lead developer, 90% of the codebase)
- **[Dxqson](https://github.com/Dxqson)**
- **[Dolyyyy](https://github.com/Dolyyyy)**
- **[lu-value](https://github.com/lu-value)**

Please respect the work that went into this project.

## Requirements

- **[dvr_power](https://github.com/DeVerino-DVR/dvr-power)** - The core spell system (required)
- **[ox_lib](https://github.com/overextended/ox_lib)** - Shared utility library
- **[oxmysql](https://github.com/overextended/oxmysql)** - MySQL adapter (some modules)
- **[es_extended](https://github.com/esx-framework/esx_core)** - ESX Framework (some modules, adapt to your framework)
- **Audio system** - Your own audio resource (see below)

## Installation

1. Install [dvr_power](https://github.com/DeVerino-DVR/dvr-power) first
2. Copy the spell module folders you want into your server's `resources` directory
3. In each module's `fxmanifest.lua`, uncomment the dependencies you have installed:
   ```lua
   shared_scripts {
       '@ox_lib/init.lua', -- uncomment this
       'config.lua'
   }
   ```
4. Replace sound/video URLs (`YOUR_SOUND_URL_HERE` / `YOUR_VIDEO_URL_HERE`) with your own hosted files
5. Add each module to your `server.cfg` (they must start **after** `dvr_power`)

## Audio System

The original audio system has been removed. All audio calls are commented out with `-- REPLACE WITH YOUR SOUND SYSTEM`.

To add sounds back:
1. Install your preferred audio resource (e.g. `xsound`, `interact-sound`, etc.)
2. Search for `REPLACE WITH YOUR SOUND SYSTEM` in the code
3. Replace the commented blocks with calls to your audio resource
4. Replace `YOUR_SOUND_URL_HERE` with actual URLs to your hosted audio files

## Available Spells (58)

### Attack Spells
| Module | Name | Description |
|---|---|---|
| dvr_basic | Basic | Basic magic projectile |
| dvr_firedrix | Firedrix | Fire circle attack |
| dvr_firepillar | Fire Pillar | Summons a pillar of fire |
| dvr_waterpillar | Water Pillar | Summons a pillar of water |
| dvr_bloodpillar | Blood Pillar | Summons a blood pillar |
| dvr_thunder | Thunder | Lightning strike spell |
| dvr_meteora | Meteora | Meteor impact spell |
| dvr_pyroth | Pyroth | Fire-based attack |
| dvr_expulsar | Expulsar | Expulsion spell |
| dvr_shockwave | Shockwave | Shockwave area attack |
| dvr_venafuria | Venafuria | Vein fury attack |
| dvr_ignifera | Ignifera | Fire bearer spell |
| dvr_petrosa | Petrosa | Rock projectile |
| dvr_mortalis | Mortalis | Death spell |
| dvr_cruorax | Cruorax | Blood control spell |
| dvr_abyrion | Abyrion | Abyss-based attack |
| dvr_sufferis | Sufferis | Suffering curse |

### Control Spells
| Module | Name | Description |
|---|---|---|
| dvr_cyclone | Cyclone | Tornado/wind force |
| dvr_impulsio | Impulsio | Push force |
| dvr_propulsia | Propulsia | Propulsion push |
| dvr_levionis | Levionis | Levitation |
| dvr_ragdolo | Ragdolo | Ragdoll target |
| dvr_snailus | Snailus | Slow target |
| dvr_juliusis | Juliusis | Knockdown spell |
| dvr_desarmis | Desarmis | Disarm target |
| dvr_silencis | Silencis | Silence target |
| dvr_coagulis | Coagulis | Coagulation control |
| dvr_opprimis | Opprimis | Suppress target |
| dvr_wallis | Wallis | Wall spell |
| dvr_staturion | Staturion | Size change |
| dvr_signalis | Signalis | Signal/mark spell |

### Support / Heal Spells
| Module | Name | Description |
|---|---|---|
| dvr_healio | Healio | Zone healing green cloud |
| dvr_ravivio | Ravivio | Revive spell |
| dvr_prothea | Prothea | Shield/protection |
| dvr_sanguiris | Sanguiris | Blood healing |

### Utility Spells
| Module | Name | Description |
|---|---|---|
| dvr_lumora | Lumora | Light spell (Lumos) |
| dvr_accyra | Accyra | Summoning spell |
| dvr_animarion | Animarion | Animal summoning |
| dvr_aloharis | Aloharis | Door unlock spell |
| dvr_hiddenis | Hiddenis | Invisibility |
| dvr_speedom | Speedom | Speed boost |
| dvr_flashstep | Flashstep | Teleport dash |
| dvr_voidrift | Voidrift | Void teleport |
| dvr_transvalis | Transvalis | Transformation |
| dvr_black | Black | Dark makeup utility |
| dvr_altis | Altis | Altitude spell |
| dvr_liquid | Liquid | Liquid transformation |
| dvr_oublitix | Oublitix | Memory wipe |
| dvr_obscura | Obscura | Darkness spell |
| dvr_tenebris | Tenebris | Shadow spell |
| dvr_fumania | Fumania | Smoke spell |
| dvr_fumora | Fumora | Fog spell |
| dvr_aquamens | Aquamens | Water summoning |
| dvr_rivilus | Rivilus | River spell |
| dvr_aveuglus | Aveuglus | Blinding spell |
| dvr_degueulis | Degueulis | Nausea spell |
| dvr_putrefactio | Putrefactio | Putrefaction |
| dvr_exposare | Exposare | Exposure spell |

## Module Structure

Each spell module follows this structure:
```
dvr_spellname/
├── fxmanifest.lua    # Resource manifest
├── config.lua        # Spell configuration
├── client/
│   └── main.lua      # Client-side spell logic
└── server/
    └── main.lua      # Server-side registration & logic
```

## Special Dependencies

Some modules have additional dependencies:

| Module | Extra Dependency | Notes |
|---|---|---|
| dvr_aloharis | [ox_doorlock](https://github.com/overextended/ox_doorlock) | Door unlock functionality |
| dvr_cruorax | [scully_emotemenu](https://github.com/scullyy/scully_emotemenu) | Emote system (has fallback) |
| dvr_accyra, dvr_prothea, dvr_lumora, dvr_ravivio | ESX Framework | Uses ESX.PlayerData / ESX.GetPlayerFromId |

## License

Free to use. Credits to DVR, [@Dxqson](https://github.com/Dxqson), [@Dolyyyy](https://github.com/Dolyyyy), and [@lu-value](https://github.com/lu-value) are **mandatory**.
