local Config <const> = {}

Config.Spell = {
    id = 'degueulis',
    name = 'Degueulis',
    description = "Sort de farce altérant brièvement l’organisme de la cible, provoquant une violente nausée.",
    icon = 'face-dizzy',
    color = 'green',
    cooldown = 8000,
    type = 'offensive',
    image = 'images/power/toxicpull.png',
    video = "YOUR_VIDEO_URL_HERE",
}

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 80.0,
    duration = 1000,
    handBone = 28422
}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_b2',
    name = 'nib@wizardsv_wand_attack_b2',
    flag = 0,
    duration = 1200
}

Config.Puke = {
    anim = {
        dict = 'anim@scripted@ulp_missions@injured_agent@',
        name = 'idle',
        flag = 1, -- boucle
        duration = -1 -- loop infini
    },
    ptfx = {
        asset = 'scr_paletoscore',
        name = 'scr_trev_puke',
        offset = { x = 0.0, y = 0.0, z = 0.0 },
        rot = { x = 0.0, y = 0.0, z = 0.0 },
        scale = 1.0,
        bone = 31086, -- HEAD
        wait = 200,
        duration = 15000
    }
}

Config.Messages = {
    noWand = {
        title = 'Degueulis',
        description = 'Vous devez equiper une baguette.',
        type = 'error',
        icon = 'face-dizzy'
    },
    noTarget = {
        title = 'Degueulis',
        description = 'Aucune cible detectee.',
        type = 'warning',
        icon = 'face-dizzy'
    }
}

_ENV.Config = Config
