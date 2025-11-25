# Guide de Téléchargement des Sons - Silva App

## Sons Recommandés de Freesound.org

### 1. **tap.mp3** - Clic UI léger
**Recommandation**: "Basic Mouse Click UI" par Philip_Berger
- **URL**: https://freesound.org/people/Philip_Berger/sounds/456966/
- **Durée**: 0.019s
- **License**: CC0 (domaine public, pas d'attribution nécessaire)
- **Alternative**: "UI Click" par EminYILDIRIM - https://freesound.org/people/EminYILDIRIM/sounds/536108/

### 2. **victory_select.mp3** - Sélection de victoire
**Recommandation**: "Button Click 1.wav" par Mellau
- **URL**: https://freesound.org/people/Mellau/sounds/506053/
- **Durée**: 1s (peut être raccourcie)
- **License**: Attribution requise
- **Alternative**: "Normal click" de Breviceps - https://freesound.org/people/Breviceps/sounds/493161/

### 3. **success.mp3** - Son de succès
**Recommandation**: "Success Jingle" par JustInvoke
- **URL**: https://freesound.org/people/JustInvoke/sounds/446111/
- **Description**: Son positif de succès pour jeux
- **License**: CC Attribution
- **Alternative**: "Complete Chime" par FoolBoyMedia - https://freesound.org/people/FoolBoyMedia/sounds/352657/

### 4. **emotion_select.mp3** - Sélection d'émotion
**Recommandation**: "success.wav" par grunz
- **URL**: https://freesound.org/people/grunz/sounds/109662/
- **Description**: Son abstrait de succès, doux
- **License**: CC Attribution

### 5. **page_turn.mp3** - Tourner la page
**Recommandation**: Utiliser un whoosh très court
- **URL**: https://freesound.org/people/qubodup/sounds/60026/
- **Durée**: 0.4s
- **License**: CC0

---

## Instructions de Téléchargement

### Étape 1: Créer un compte Freesound.org
Allez sur https://freesound.org et créez un compte gratuitement (nécessaire pour télécharger).

### Étape 2: Télécharger les sons
Pour chaque son recommandé:
1. Cliquez sur le lien URL
2. Cliquez sur le bouton "Download" (télécharger)
3. Le fichier sera téléchargé (généralement en .wav)

### Étape 3: Convertir et Renommer
Les fichiers seront en .wav - vous devez les convertir en .mp3 et les renommer.

**Option A: En ligne (facile)**
1. Allez sur https://cloudconvert.com/wav-to-mp3
2. Uploadez chaque fichier .wav
3. Téléchargez le .mp3
4. Renommez selon le tableau ci-dessous

**Option B: Avec ffmpeg (ligne de commande)**
```bash
cd ~/Downloads
# Installer ffmpeg si nécessaire
brew install ffmpeg

# Convertir chaque fichier
ffmpeg -i "fichier_telecharge.wav" -b:a 128k tap.mp3
# Répétez pour chaque son
```

### Étape 4: Placer les fichiers
Copiez tous les fichiers .mp3 dans le dossier:
```bash
cp tap.mp3 victory_select.mp3 success.mp3 emotion_select.mp3 page_turn.mp3 /Users/daoud/Work/ma_bulle/assets/sounds/
```

---

## Tableau de Correspondance

| Fichier téléchargé | À renommer en |
|-------------------|---------------|
| 456966__philip_berger__basic-mouse-click-ui.wav | tap.mp3 |
| 506053__mellau__button-click-1.wav | victory_select.mp3 |
| 446111__justinvoke__success-jingle.wav | success.mp3 |
| 109662__grunz__success.wav | emotion_select.mp3 |
| 60026__qubodup__whoosh.wav | page_turn.mp3 |

---

## Option Rapide: Script d'Automatisation

Si vous voulez automatiser tout le processus (après avoir téléchargé les fichiers manuellement dans ~/Downloads):

```bash
#!/bin/bash
cd ~/Downloads

# Convertir et renommer
ffmpeg -i "456966__philip_berger__basic-mouse-click-ui.wav" -b:a 96k tap.mp3
ffmpeg -i "506053__mellau__button-click-1.wav" -b:a 96k victory_select.mp3
ffmpeg -i "446111__justinvoke__success-jingle.wav" -b:a 128k success.mp3
ffmpeg -i "109662__grunz__success.wav" -b:a 96k emotion_select.mp3
ffmpeg -i "60026__qubodup__whoosh.wav" -b:a 96k page_turn.mp3

# Copier vers le projet
cp tap.mp3 victory_select.mp3 success.mp3 emotion_select.mp3 page_turn.mp3 /Users/daoud/Work/ma_bulle/assets/sounds/

echo "✅ Sons installés avec succès!"
```

---

## Après l'Installation

Une fois les fichiers en place, décommentez les lignes 71-72 dans `lib/services/audio_service.dart`:

```dart
await player.setVolume(finalVolume);
await player.play(AssetSource('sounds/$soundType.mp3'));
```

Puis faites un hot restart (appuyez sur 'R' dans le terminal flutter run).

---

## Licences

N'oubliez pas d'ajouter les attributions requises dans votre app si vous utilisez les sons avec license CC Attribution:
- Mellau (Button Click, Whoosh)
- JustInvoke (Success Jingle)
- grunz (success.wav)
- Robinhood76 (si utilisé)

Les sons CC0 (Philip_Berger, giddster, qubodup) ne nécessitent pas d'attribution.
