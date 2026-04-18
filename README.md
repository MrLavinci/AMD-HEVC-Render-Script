# AMD HEVC Render Script 🚀

Ein performantes Bash-Script für Arch Linux, um Videos mit Hardware-Beschleunigung (AMD AMF) in das HEVC-Format (H.265) zu konvertieren. Es bietet eine detaillierte Fortschrittsanzeige direkt im Terminal.

## Features
* **AMD Hardware-Beschleunigung:** Nutzt den `hevc_amf` Encoder für extrem schnelles Rendering.
* **Echtzeit-Statistiken:** Anzeige von Fortschrittsbalken, FPS, aktueller Geschwindigkeit (Speed), Dateigröße und ETA (Ankunftszeit).
* **Saubere Bash-Implementierung:** Nutzt `pipefail` und `mktemp` für maximale Stabilität und Sicherheit.

## 🛠 Voraussetzungen

Da dieses Script für Arch Linux und AMD-GPUs konzipiert ist, werden folgende Pakete benötigt:

1. FFmpeg mit AMF-Support:
   ```bash
   sudo pacman -S ffmpeg
   
2. AMD Treiber: Du benötigst die AMF-Laufzeitumgebung (z. B. amdgpu-pro-libamf oder libamf aus dem AUR).

3. Core-Utilities: ffprobe, awk und procps-ng (sind unter Arch meist vorinstalliert).


## Installation

1.1 Klonen des Repositories:

git clone [https://github.com/MrLavinci/AMD-HEVC-Render-Script.git](https://github.com/MrLavinci/AMD-HEVC-Render-Script.git)
cd AMD-HEVC-Render-Script

# Alternativ
1.2 Download als ZIP und entpacken

2. chmod +x render.sh

## Nutzung

Die Bedienung ist denkbar einfach. Gib einfach die Eingabedatei und den gewünschten Zielpfad an:

./render.sh mein_video.mp4 output_ordner/fertig.mp4


## Beispiel der Ausgabe:

🎬 [████████░░░░░░░░░░░░] 35.5% | 🚀 5.20x | 🎞️ 120fps | 📦 142.5 MiB | ETA 00:02:15 | ⏳ 01:10

## Lizenz

Dieses Projekt ist unter der GNU General Public License v3.0 (GPLv3) lizenziert. Das bedeutet:

- Du darfst das Script frei nutzen, teilen und verändern.

- Wenn du das Script veränderst und veröffentlichst, müssen deine Änderungen ebenfalls unter der GPLv3 stehen.

- Der Urheberrechtshinweis von MrLavinci muss erhalten bleiben.

Details findest du in der LICENSE Datei.

Entwickelt von MrLavinci (2026).
