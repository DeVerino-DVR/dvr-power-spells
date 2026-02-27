# 📜 Guide Complet des Sorts - Documentation Staff

> **Dernière mise à jour:** Décembre 2025  
> **Total:** 31 sorts disponibles

---

## 🎯 Commandes Admin (PZFX)

| Commande | Description |
|----------|-------------|
| `lspell <playerId> <spellId>` | Donne un sort à un joueur |
| `uspell <playerId> <spellId>` | Retire un sort à un joueur |
| `ensure th_<spell>` | Redémarre un module de sort |
| `stop th_<spell>` | Arrête un module de sort |
| `refresh` | Recharge la liste des ressources |

**Exemple:** `lspell 1 thunder` → Donne Thunder au joueur ID 1

---

## ⚔️ SORTS D'ATTAQUE (13)

### 1. Basicus
| Propriété | Valeur |
|-----------|--------|
| **ID** | `basic` |
| **Type** | Attaque |
| **Cooldown** | 2 secondes |
| **Dégâts** | 0 base + **5 par niveau** |
| **Portée** | 1000m max |

**Description:** Projectile vert basique sans effet spécial.

**Effets visuels:**
- Projectile vert lumineux
- Vitesse: 30.0

---

### 2. Desarmis
| Propriété | Valeur |
|-----------|--------|
| **ID** | `desarmis` |
| **Type** | Attaque |
| **Cooldown** | 8 secondes |
| **Portée** | 15m max |

**Description:** Désarme le joueur ciblé en lui retirant sa baguette équipée.

**Effets visuels:**
- Projectile rouge (`veh_light_red_trail`)
- Impact avec explosion de particules
- Lumière rouge (R:255 G:50 B:50)
- Shake caméra à l'impact

**Effets gameplay:**
- Déséquipe la baguette de la cible
- La cible reçoit une notification

---

### 3. Expulsar
| Propriété | Valeur |
|-----------|--------|
| **ID** | `expulsar` |
| **Type** | Attaque |
| **Rayon** | 35m |
| **Force** | 5.0 (+ 5.0 vertical) |

**Description:** Onde de choc qui propulse tous les joueurs proches.

**Effets visuels:**
- Onde de choc (`veh_sub_crush`)
- Explosion invisible mais audible
- Shake caméra (intensité 0.3, portée 20m)

**Effets gameplay:**
- Propulse les joueurs dans les airs
- Durée de l'effet: 1 seconde

---

### 4. Fire Pillar
| Propriété | Valeur |
|-----------|--------|
| **ID** | `firepillar` |
| **Type** | Attaque |
| **Cooldown** | 3 secondes |
| **Dégâts** | 0 base + **8 par niveau** |
| **Durée** | 8 secondes |

**Description:** Crée une colonne de feu devant le lanceur.

**Effets visuels:**
- Modèle: `nib_fire_tornado`
- Rotation: 160°/seconde
- Colonne de feu visible

**Effets gameplay:**
- Dégâts de zone continus
- Scale avec le niveau du joueur

---

### 5. Incendrix
| Propriété | Valeur |
|-----------|--------|
| **ID** | `incendrix` |
| **Type** | Attaque |
| **Rayon** | 4m |
| **Durée** | 5 secondes |
| **Dégâts** | 15 HP / 400ms |

**Description:** Crée un cercle de feu au sol qui brûle les ennemis.

**Effets visuels:**
- 3 anneaux de flammes (48 + 24 + 12 flammes)
- Centre avec `ent_amb_foundry_fire`
- Échelles: 1.5 / 1.3 / 1.0

**Effets gameplay:**
- Dégâts over time dans la zone
- Total potentiel: ~187 HP sur 5s

---

### 6. Mortalis
| Propriété | Valeur |
|-----------|--------|
| **ID** | `mortalis` |
| **Type** | Attaque |
| **Vitesse projectile** | 100.0 |

**Description:** Projectile explosif mortel.

**Effets visuels:**
- Projectile: `wizardsV_nib_avadakedavra_ray`
- Explosion type 1 (visible + audible)
- Particules de feu (`ns_ptfx` → `fire`, x8)
- Fumée (`exp_grd_bzgas_smoke`, x3)
- Shake caméra (intensité 1.0, portée 15m)

**Effets gameplay:**
- Explosion à l'impact
- Dégâts d'explosion: 0.05 (légers)

---

### 7. Shockwave
| Propriété | Valeur |
|-----------|--------|
| **ID** | `shockwave` |
| **Type** | Attaque |
| **Cooldown** | 7 secondes |
| **Rayon** | 10m |
| **Ragdoll** | 2 secondes |

**Description:** Déclenche une onde de choc qui renverse les proches.

**Effets visuels:**
- Anneau d'eau (`veh_air_turbulance_water`)
- Étincelles (`ent_brk_sparking_wires`)
- Fumée (`exp_water`)
- Shake caméra (0.45 intensité, 30m portée)

**Effets gameplay:**
- Ragdoll tous les joueurs dans le rayon
- Durée du ragdoll: 2 secondes

---

### 8. Solar Burst
| Propriété | Valeur |
|-----------|--------|
| **ID** | `solarburst` |
| **Type** | Attaque |
| **Cooldown** | 8 secondes |
| **Rayon** | 10m |
| **Brûlure** | 4 secondes |

**Description:** Déchaîne une explosion solaire qui aveugle et brûle.

**Effets visuels:**
- Charge (`ent_amb_sparking_wires_sp`)
- Anneau (`exp_grd_bzgas_smoke`)
- Rayons (`ent_amb_elec_fire_sp`)
- Flash paparazzi (`ent_anim_paparazzi_flash`)
- Flare (`exp_grd_flare`)
- Shake caméra (0.5 intensité, 30m portée)

**Effets gameplay:**
- Effet d'aveuglement
- Brûlure pendant 4 secondes

---

### 9. Starlance
| Propriété | Valeur |
|-----------|--------|
| **ID** | `starlance` |
| **Type** | Attaque |
| **Cooldown** | 9 secondes |
| **Portée** | 65m max |
| **Rayon impact** | 10m |
| **Ragdoll** | 2.2 secondes |

**Description:** Un trait d'étoile tombe du ciel et frappe la zone ciblée.

**Effets visuels:**
- Rayon descendant (`ent_amb_sparking_wires_sp`)
- Aura (`veh_exhaust_spacecraft`)
- Explosion (`ent_amb_elec_fire_sp`)
- Fumée au sol (`exp_grd_bzgas_smoke`)
- Son personnalisé (URL externe)
- Shake caméra (0.6 intensité, 35m portée)

**Effets gameplay:**
- Impact du ciel vers le sol
- Ragdoll de zone (2.2s)
- Effet persistant 2.5s

---

### 10. Sufferis
| Propriété | Valeur |
|-----------|--------|
| **ID** | `sufferis` |
| **Type** | Attaque |
| **Cooldown** | 8 secondes |
| **Ragdoll** | 10 secondes |
| **Hémorragie** | 10 secondes |

**Description:** Projette un rayon électrique qui fait trébucher et provoque une hémorragie.

**Effets visuels:**
- Props éclairs: `wizardsV_nib_wizards_lightning_*`
- Fumée (`scr_adversary_gunsmith_weap_smoke`)
- Shake caméra (0.6 intensité)
- Effet de sang à l'écran

**Effets gameplay:**
- Ragdoll prolongé (10s)
- Effet d'hémorragie visuel
- Très puissant en CC

---

### 11. Thunder
| Propriété | Valeur |
|-----------|--------|
| **ID** | `thunder` |
| **Type** | Attaque |
| **Cooldown** | 4.5 secondes |
| **Ragdoll base** | 2 secondes |
| **Ragdoll max** | 5 secondes |

**Description:** Un éclair ciblé qui fait chuter la cible touchée.

**Effets visuels:**
- Props éclairs: `wizardsV_nib_wizards_lightning_*`
- Particules de fumée
- Sons personnalisés (2 URL externes)
- Shake fort pendant le cast (1.2 intensité)

**Effets gameplay:**
- Ragdoll scaling: 2s base + 350ms/niveau (max 5s)
- Portée quasi-infinie (999999m)

---

### 12. Void Rift
| Propriété | Valeur |
|-----------|--------|
| **ID** | `voidrift` |
| **Type** | Attaque |
| **Cooldown** | 9 secondes |
| **Rayon d'attraction** | 12m |
| **Force d'attraction** | 2.8 |
| **Durée** | 4.5 secondes |
| **Rayon explosion** | 8m |

**Description:** Ouvre une fissure qui attire les ennemis puis explose.

**Effets visuels:**
- Fissure (`ent_amb_sparking_wires_sp`)
- Aura (`veh_exhaust_spacecraft`)
- Explosion finale (`exp_grd_plane_small`)

**Effets gameplay:**
- Phase 1 (0-3.5s): Attraction continue
- Phase 2 (3.5s): Explosion de zone

---

### 13. Water Pillar
| Propriété | Valeur |
|-----------|--------|
| **ID** | `waterpillar` |
| **Type** | Attaque |
| **Cooldown** | 4 secondes |
| **Durée** | 6 secondes |
| **Rotation** | 90°/seconde |

**Description:** Projette un jet d'eau qui jaillit au point d'impact.

**Effets visuels:**
- Modèle: `wizardsV_nib_accio_ray`
- Bulles (`ent_amb_tnl_bubbles_sml`)
- Éclaboussures (`veh_air_turbulance_water`, `exp_water`)
- Fontaine (`ent_amb_fountain_pour`)

---

## 🛡️ SORTS DE DÉFENSE (1)

### 14. Prothea
| Propriété | Valeur |
|-----------|--------|
| **ID** | `prothea` |
| **Type** | Défense |
| **Cooldown** | 1 seconde |
| **Touche** | P |
| **Bloc dégâts** | 100% |

**Description:** Invoque un bouclier magique qui bloque les dégâts.

**Scaling par niveau:**
| Niveau | Durée | Godmode |
|--------|-------|---------|
| 0-1 | 1.2s | ❌ |
| 2 | 1.5s | ✅ |
| 3 | 1.8s | ✅ |
| 4 | 2.1s | ✅ |
| 5 | 2.4s | ✅ |

**Effets visuels:**
- Modèle: `nib_protego_prop`
- Flash de cast (`ent_amb_elec_crackle`, x3)
- Aura en boucle (bleu électrique)
- Lumière pulsante (période 1.6s)
- Flash de rupture (`ent_sht_elec_fire_sp`)

**Effets gameplay:**
- Bloque 100% des dégâts
- Godmode activé niveau 2+
- Props de bouclier visibles

---

## 🎮 SORTS DE CONTRÔLE (3)

### 15. Levionis
| Propriété | Valeur |
|-----------|--------|
| **ID** | `levionis` |
| **Type** | Contrôle |
| **Durée** | 5 secondes |
| **Hauteur** | 1.5m |
| **Portée contrôle** | 15-35m |

**Description:** Fait léviter un joueur ou objet et permet de le contrôler.

**Effets visuels:**
- Flash de cast (`ent_amb_elec_crackle`, x2)
- Aura sur joueur (bleu cyan)
- Aura sur objet
- Lumière pulsante (période 1.8s)
- Flash de relâche (`ent_sht_elec_fire_sp`)

**Effets gameplay:**
- Lévitation à 1.5m du sol
- Temps de montée: 1 seconde
- Peut contrôler objets (rayon 3m)
- Force de lâcher: 12.0
- Animation ragdoll sur la cible

---

### 16. Ragdolo
| Propriété | Valeur |
|-----------|--------|
| **ID** | `ragdolo` |
| **Type** | Contrôle |
| **Cooldown** | 4 secondes |
| **Durée base** | 2 secondes |
| **Durée max** | 5 secondes |

**Description:** Projette un rayon qui fait trébucher la cible touchée.

**Scaling:** +350ms par niveau

**Effets visuels:**
- Projectile violet
- Vitesse: 30.0
- Portée: 1000m

**Effets gameplay:**
- Ragdoll immédiat sur la cible
- Durée variable selon niveau

---

### 17. Staturion
| Propriété | Valeur |
|-----------|--------|
| **ID** | `staturion` |
| **Type** | Contrôle |
| **Cooldown** | 20 secondes |
| **Durée pétrification** | 15 secondes |

**Description:** Pétrifie complètement la cible pendant 15 secondes.

**Effets visuels:**
- Projectile: `wizardsV_nib_avadakedavra_ray` (vitesse 130)
- Particules baguette (bleu clair)
- Effet freeze (`scr_alien_freeze_ray`)
- Aura gelée (`ent_amb_elec_crackle_sp`)

**Effets gameplay:**
- Immobilisation totale
- CC le plus long du jeu (15s)
- Cooldown élevé (20s)

---

## 💚 SORTS DE SUPPORT (2)

### 18. Healio
| Propriété | Valeur |
|-----------|--------|
| **ID** | `healio` |
| **Type** | Support |
| **Rayon** | 8m |
| **Soin** | 20 HP / 2 secondes |
| **Durée** | 8 secondes |
| **Max joueurs** | 10 |

**Description:** Crée une zone de soin qui régénère les alliés proches.

**Total soin potentiel:** 80 HP sur 8 secondes

**Effets visuels:**
- Nuage vert (`exp_grd_bzgas_smoke`, x3)
- Particules vertes (`scr_rcbarry2_vine_green`)
- Anneau de fumée (`exp_extinguisher`)
- Projectile vert initial

**Effets gameplay:**
- Zone AoE statique
- Soin toutes les 2 secondes
- Peut soigner jusqu'à 10 joueurs simultanément

---

### 19. Ravivio
| Propriété | Valeur |
|-----------|--------|
| **ID** | `ravivio` |
| **Type** | Support |
| **Cooldown** | 10 secondes |
| **Portée** | 100m max |

**Description:** Réanime un joueur mort à proximité grâce à la magie.

**Effets visuels:**
- Particules baguette cyan
- Particules de réanimation vertes (`scr_rcbarry2_vine_green`)
- Projectile: `wizardsV_nib_avadakedavra_ray`

**Effets gameplay:**
- Cible le joueur mort le plus proche
- Réanimation instantanée à l'impact
- Notification aux deux joueurs

---

## 🔧 SORTS UTILITAIRES (11)

### 20. Accyra
| Propriété | Valeur |
|-----------|--------|
| **ID** | `accyra` |
| **Type** | Utilitaire |
| **Rayon objets** | 5m |
| **Vitesse attraction** | 20.0 |
| **Durée** | 5 secondes |
| **Portée max** | 100m |

**Description:** Attire un objet vers le lanceur.

**Effets visuels:**
- Projectile: `nib_accio_ray`
- Particules baguette (bleu clair)
- Aura électrique (`ent_amb_elec_crackle_sp`)
- Trail projectile
- Impact avec shockwave
- Lumière bleue (R:60 G:140 B:255)

---

### 21. Aloharis
| Propriété | Valeur |
|-----------|--------|
| **ID** | `aloharis` |
| **Type** | Utilitaire |
| **Cooldown** | 7 secondes |
| **Portée** | 10m max |
| **Cast time** | 2.2 secondes |

**Description:** Déverrouille les portes ox_doorlock ciblées.

**Effets visuels:**
- Pré-effet: Rayon bleu vers la porte (2.4s)
- Marker rotatif sur la porte
- Outline de la porte
- Burst à l'ouverture (`scr_clown_appears`)
- Confettis (`scr_xs_confetti_burst`)
- Étincelles (`scr_xs_x16_sparkle_trail`, x4)
- Lumière cyan brillante
- PostFX: `SuccessNeutral`

**Effets gameplay:**
- Déverrouille portes ox_doorlock
- Certaines portes peuvent être blacklistées

---

### 22. Animarion
| Propriété | Valeur |
|-----------|--------|
| **ID** | `animarion` |
| **Type** | Utilitaire |
| **Durée** | 30 secondes |
| **Cooldown** | 45 secondes |

**Description:** Transformation en animal aléatoire.

**Animaux disponibles:**
- Chat, Berger, Husky, Retriever
- Cerf, Sanglier, Lapin, Rat
- Corbeau, Mouette, Poule
- Cochon, Coyote

**Effets visuels:**
- Particules baguette orange
- Trail projectile orange
- Effet téléportation (`scr_alien_teleport`)
- Fumée orange (`exp_grd_bzgas_smoke`)

---

### 23. Aquamens
| Propriété | Valeur |
|-----------|--------|
| **ID** | `aquamens` |
| **Type** | Utilitaire |
| **Cooldown** | 6 secondes |
| **Portée** | 60m max |

**Description:** Téléportation d'eau instantanée vers le point visé.

**Effets visuels:**
- Chemin d'eau (`veh_air_turbulance_water`)
- Bulles (`ent_amb_tnl_bubbles_sml`)
- Éclaboussure à l'arrivée (`exp_water`)
- Fontaine (`ent_amb_fountain_pour`)

---

### 24. Flashstep
| Propriété | Valeur |
|-----------|--------|
| **ID** | `flashstep` |
| **Type** | Utilitaire |
| **Cooldown** | 6 secondes |
| **Portée** | 28m max |
| **Durée visuelle** | 350ms |

**Description:** Téléportation éclair instantanée vers le point visé.

**Effets visuels:**
- Trail (`veh_exhaust_spacecraft`)
- Arrivée (`exp_water`)
- Électricité (`ent_brk_sparking_wires`)
- Particules baguette (`ent_amb_tnl_bubbles_sml`)
- Son personnalisé (URL externe)
- Shake caméra (0.6 intensité, 25m portée)

---

### 25. Fumania
| Propriété | Valeur |
|-----------|--------|
| **ID** | `fumania` |
| **Type** | Utilitaire |
| **Cooldown** | 8 secondes |
| **Portée** | 60m max |

**Description:** Échange ta position avec la cible dans un nuage de fumée.

**Effets visuels:**
- Fumée épaisse (`ent_amb_fbi_door_smoke`)
- Durée fumée: 3 secondes

**Effets gameplay:**
- Swap de position instantané
- Affecte joueurs et PNJ

---

### 26. Hiddenis
| Propriété | Valeur |
|-----------|--------|
| **ID** | `hiddenis` |
| **Type** | Utilitaire |
| **Cooldown** | 20 secondes |
| **Durée** | 15 secondes |
| **Visibilité locale** | 20% (alpha 51) |

**Description:** Se rend quasi invisible et disparaît du réseau.

**Effets gameplay:**
- Invisibilité visuelle (80%)
- Disparition du réseau (autres joueurs ne voient pas)
- Utile pour infiltration/fuite

---

### 27. Lumora
| Propriété | Valeur |
|-----------|--------|
| **ID** | `lumora` |
| **Type** | Utilitaire |
| **Niveaux** | 0-5 |

**Description:** Projectile lumineux qui éclaire la zone.

**Scaling par niveau:**
| Niveau | Portée | Intensité | Distance max |
|--------|--------|-----------|--------------|
| 0 | 1.4 | 3.0 | 40m |
| 1 | 1.8 | 4.5 | 55m |
| 2 | 2.2 | 6.0 | 70m |
| 3 | 2.6 | 7.0 | 85m |
| 4 | 2.8 | 7.5 | 95m |
| 5 | 3.0 | 8.0 | 100m |

---

### 28. Obscura
| Propriété | Valeur |
|-----------|--------|
| **ID** | `obscura` |
| **Type** | Utilitaire |
| **Cooldown** | 10 secondes |
| **Durée** | 30 secondes |

**Description:** Plonge la zone dans l'obscurité totale.

**Effets gameplay:**
- Blackout de zone
- Contre Lumora
- Utile pour embuscades

---

### 29. Rivilus
| Propriété | Valeur |
|-----------|--------|
| **ID** | `rivilus` |
| **Type** | Utilitaire |
| **Cooldown** | 12 secondes |
| **Durée** | 8 secondes |
| **Max entités** | 50 |

**Description:** Révèle les joueurs, PNJ et objets proches en les surlignant.

**Scaling par niveau:**
| Niveau | Rayon |
|--------|-------|
| Base | 30m |
| +3m/niveau | ... |
| Max | 55m |

**Couleurs d'outline:**
- Joueurs/PNJ: Bleu (90, 180, 255)
- Objets: Jaune (220, 200, 120)
- Véhicules: Orange (255, 180, 120)

---

### 30. Speedom
| Propriété | Valeur |
|-----------|--------|
| **ID** | `speedom` |
| **Type** | Utilitaire |
| **Cooldown** | 10 secondes |
| **Durée** | 30 secondes |
| **Boost** | x1.49 vitesse |
| **Portée** | 60m max |

**Description:** Accélère le lanceur ou la cible pendant 30 secondes.

**Effets visuels:**
- Particules de bulles sur les pieds
- Effet continu pendant la durée

**Effets gameplay:**
- Peut cibler soi-même ou un allié
- Multiplicateur marche ET sprint: x1.49

---

### 31. Transvalis
| Propriété | Valeur |
|-----------|--------|
| **ID** | `transvalis` |
| **Type** | Utilitaire |
| **Durée max** | 15 secondes |
| **Hauteur max** | 300m |

**Description:** Mode spectral permettant de traverser les murs.

**Contrôles:**
| Touche | Action |
|--------|--------|
| W/A/S/D | Déplacement |
| Space | Monter |
| Ctrl | Descendre |
| Shift | Vitesse rapide (x1.8) |
| Alt | Vitesse lente (x0.25) |
| X | Annuler |

**Vitesses:**
- Normal: 0.9
- Rapide: 1.8
- Lente: 0.25

**Effets visuels:**
- Fumée noire (`scr_adversary_weap_smoke`)
- Trail de mouvement
- Aura électrique
- Lumière pulsante
- Effet de téléportation début/fin

---

## 📊 Tableaux Récapitulatifs

### Par Type
| Type | Nombre | % |
|------|--------|---|
| Attaque | 13 | 42% |
| Utilitaire | 11 | 35% |
| Contrôle | 3 | 10% |
| Support | 2 | 6% |
| Défense | 1 | 3% |

### Sorts avec Scaling par Niveau
| Sort | Stat qui scale |
|------|----------------|
| Basicus | Dégâts (+5/lvl) |
| Fire Pillar | Dégâts (+8/lvl) |
| Thunder | Durée ragdoll (+350ms/lvl) |
| Ragdolo | Durée ragdoll (+350ms/lvl) |
| Prothea | Durée bouclier + Godmode |
| Lumora | Portée + Intensité |
| Rivilus | Rayon de scan (+3m/lvl) |

### Cooldowns les plus courts
| Sort | Cooldown |
|------|----------|
| Prothea | 1s |
| Basicus | 2s |
| Fire Pillar | 3s |
| Ragdolo | 4s |
| Water Pillar | 4s |
| Thunder | 4.5s |

### Cooldowns les plus longs
| Sort | Cooldown |
|------|----------|
| Animarion | 45s |
| Hiddenis | 20s |
| Staturion | 20s |
| Rivilus | 12s |
| Ravivio | 10s |
| Obscura | 10s |

---

## 🎨 Assets Visuels Communs

### Dictionnaires de Particules
- `core` - Effets de base GTA
- `scr_rcbarry1` / `scr_rcbarry2` - Effets spéciaux
- `scr_xs_celebration` - Confettis, célébrations
- `scr_bike_adversary` - Fumées
- `ns_ptfx` - Feu

### Props de Sort
- `wizardsV_nib_avadakedavra_ray` - Rayon mortel
- `wizardsV_nib_accio_ray` / `nib_accio_ray` - Rayon d'attraction
- `nib_protego_prop` - Bouclier Prothea
- `nib_fire_tornado` - Tornade de feu
- `wizardsV_nib_wizards_lightning_*` - Éclairs

---

*Document généré pour l'équipe Staff - Ne pas diffuser aux joueurs*

