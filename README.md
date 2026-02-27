# th-power-spells - Spell Modules for th_power

58 spell modules for the [th_power](https://github.com/DeVerino-DVR/dvr-power) magic system on FiveM.

> Originally developed for the VLight RP event.

## Important Notice

This script is **complex**. It was specifically designed for a custom FiveM server environment. If you are not experienced with FiveM development or adapting advanced systems, it will be very difficult to install or modify correctly.

**No support will be provided. There will be no help, assistance, or custom adaptation. The system is given as-is.**

If you use it, you must know what you are doing.

## Credits

These scripts are distributed for free. Credits must remain attributed to:
- **VLight** (original author)
- **@dxqson**
- **@dolyyy**
- **@lu_value**

Please respect the work that went into this project.

## Requirements

- **[th_power](https://github.com/DeVerino-DVR/dvr-power)** - The core spell system (required)
- **[ox_lib](https://github.com/overextended/ox_lib)** - Shared utility library
- **[oxmysql](https://github.com/overextended/oxmysql)** - MySQL adapter (some modules)
- **[es_extended](https://github.com/esx-framework/esx_core)** - ESX Framework (some modules, adapt to your framework)
- **Audio system** - Your own audio resource (see below)

## Installation

1. Install [th_power](https://github.com/DeVerino-DVR/dvr-power) first
2. Copy the spell module folders you want into your server's `resources` directory
3. In each module's `fxmanifest.lua`, uncomment the dependencies you have installed:
   ```lua
   shared_scripts {
       '@ox_lib/init.lua', -- uncomment this
       'config.lua'
   }
   ```
4. Replace sound/video URLs (`YOUR_SOUND_URL_HERE` / `YOUR_VIDEO_URL_HERE`) with your own hosted files
5. Add each module to your `server.cfg` (they must start **after** `th_power`)

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
| th_basic | Basic | Basic magic projectile |
| th_firedrix | Firedrix | Fire circle attack |
| th_firepillar | Fire Pillar | Summons a pillar of fire |
| th_waterpillar | Water Pillar | Summons a pillar of water |
| th_bloodpillar | Blood Pillar | Summons a blood pillar |
| th_thunder | Thunder | Lightning strike spell |
| th_meteora | Meteora | Meteor impact spell |
| th_pyroth | Pyroth | Fire-based attack |
| th_expulsar | Expulsar | Expulsion spell |
| th_shockwave | Shockwave | Shockwave area attack |
| th_venafuria | Venafuria | Vein fury attack |
| th_ignifera | Ignifera | Fire bearer spell |
| th_petrosa | Petrosa | Rock projectile |
| th_mortalis | Mortalis | Death spell |
| th_cruorax | Cruorax | Blood control spell |
| th_abyrion | Abyrion | Abyss-based attack |
| th_sufferis | Sufferis | Suffering curse |

### Control Spells
| Module | Name | Description |
|---|---|---|
| th_cyclone | Cyclone | Tornado/wind force |
| th_impulsio | Impulsio | Push force |
| th_propulsia | Propulsia | Propulsion push |
| th_levionis | Levionis | Levitation |
| th_ragdolo | Ragdolo | Ragdoll target |
| th_snailus | Snailus | Slow target |
| th_juliusis | Juliusis | Knockdown spell |
| th_desarmis | Desarmis | Disarm target |
| th_silencis | Silencis | Silence target |
| th_coagulis | Coagulis | Coagulation control |
| th_opprimis | Opprimis | Suppress target |
| th_wallis | Wallis | Wall spell |
| th_staturion | Staturion | Size change |
| th_signalis | Signalis | Signal/mark spell |

### Support / Heal Spells
| Module | Name | Description |
|---|---|---|
| th_healio | Healio | Zone healing green cloud |
| th_ravivio | Ravivio | Revive spell |
| th_prothea | Prothea | Shield/protection |
| th_sanguiris | Sanguiris | Blood healing |

### Utility Spells
| Module | Name | Description |
|---|---|---|
| th_lumora | Lumora | Light spell (Lumos) |
| th_accyra | Accyra | Summoning spell |
| th_animarion | Animarion | Animal summoning |
| th_aloharis | Aloharis | Door unlock spell |
| th_hiddenis | Hiddenis | Invisibility |
| th_speedom | Speedom | Speed boost |
| th_flashstep | Flashstep | Teleport dash |
| th_voidrift | Voidrift | Void teleport |
| th_transvalis | Transvalis | Transformation |
| th_black | Black | Dark makeup utility |
| th_altis | Altis | Altitude spell |
| th_liquid | Liquid | Liquid transformation |
| th_oublitix | Oublitix | Memory wipe |
| th_obscura | Obscura | Darkness spell |
| th_tenebris | Tenebris | Shadow spell |
| th_fumania | Fumania | Smoke spell |
| th_fumora | Fumora | Fog spell |
| th_aquamens | Aquamens | Water summoning |
| th_rivilus | Rivilus | River spell |
| th_aveuglus | Aveuglus | Blinding spell |
| th_degueulis | Degueulis | Nausea spell |
| th_putrefactio | Putrefactio | Putrefaction |
| th_exposare | Exposare | Exposure spell |

## Module Structure

Each spell module follows this structure:
```
th_spellname/
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
| th_aloharis | [ox_doorlock](https://github.com/overextended/ox_doorlock) | Door unlock functionality |
| th_cruorax | [scully_emotemenu](https://github.com/scullyy/scully_emotemenu) | Emote system (has fallback) |
| th_accyra, th_prothea, th_lumora, th_ravivio | ESX Framework | Uses ESX.PlayerData / ESX.GetPlayerFromId |

## License

Free to use. Credits to VLight, @dxqson, @dolyyy, and @lu_value are **mandatory**.
