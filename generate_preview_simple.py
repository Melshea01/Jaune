#!/usr/bin/env python3
"""
Génère un PDF simple du rendu BEJAUNE sans dépendances externes
Utilise les capacités natives de MacOS
"""

import subprocess
import os

html_content = """
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BEJAUNE - Rendu du Montage Photo</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;
            margin: 0;
            padding: 40px;
            background: #f5f5f5;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            text-align: center;
            color: #333;
            margin-bottom: 10px;
        }
        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
            font-size: 14px;
        }
        .preview-container {
            background: linear-gradient(180deg, #DAA520 0%, #8B4513 100%);
            width: 300px;
            height: 400px;
            margin: 30px auto;
            border: 2px solid #ddd;
            border-radius: 16px;
            position: relative;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .pv-box {
            position: absolute;
            top: 16px;
            right: 16px;
            width: 90px;
            height: 30px;
            background: linear-gradient(135deg, #64C8FF 0%, #3B7ADB 100%);
            border: 3px solid #000;
            border-radius: 12px;
            display: flex;
            flex-direction: row;
            align-items: flex-end;
            justify-content: space-between;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            color: white;
            font-weight: bold;
            padding: 4px 6px 4px 6px;
            gap: 2px;
        }
        .pv-label {
            font-size: 9px;
            opacity: 0.7;
            line-height: 1;
        }
        .pv-value {
            font-size: 16px;
            line-height: 1;
        }
        .pv-avatar {
            font-size: 18px;
        }
        .health-bar {
            position: absolute;
            bottom: 36px;
            left: 50%;
            transform: translateX(-50%);
            width: 84px;
            height: 8px;
            background: rgba(200, 200, 200, 0.6);
            border: 1px solid rgba(255, 255, 255, 0.35);
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 6px rgba(0,0,0,0.18);
        }
        .health-fill {
            height: 100%;
            width: 75%;
            background: linear-gradient(90deg, #43e97b 0%, #38f9d7 100%);
            border-radius: 12px;
        }
        .jaune-text {
            position: absolute;
            bottom: 12px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 14px;
            font-weight: 700;
            color: rgba(0, 0, 0, 0.6);
            letter-spacing: 1px;
        }
        .features {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #eee;
        }
        .feature {
            display: flex;
            align-items: center;
            padding: 10px 0;
            font-size: 14px;
            color: #555;
        }
        .feature::before {
            content: "✓";
            color: #43e97b;
            font-weight: bold;
            margin-right: 10px;
            font-size: 16px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>BEJAUNE</h1>
        <p class="subtitle">Rendu du Montage Photo - Mode Debug</p>
        
        <div class="preview-container">
            <div class="pv-box">
                <div style="display: flex; align-items: flex-end; gap: 1px;">
                    <div class="pv-label">PV</div><div class="pv-value">75</div>
                </div>
                <div class="pv-avatar">🍋</div>
            </div>
            
            <div class="health-bar">
                <div class="health-fill"></div>
            </div>
            
            <div class="jaune-text">JAUNE</div>
        </div>
        
        <div class="features">
            <div class="feature">Haut-droite: Zone PV avec avatar 🍋</div>
            <div class="feature">Bas centré: Texte "JAUNE"</div>
            <div class="feature">Barre de santé centrée (au-dessus de JAUNE)</div>
            <div class="feature">Aspect ratio: 9/12 (300x400px)</div>
            <div class="feature">Pas de carte de message</div>
        </div>
    </div>
</body>
</html>
"""

# Écrire le HTML
html_path = "/tmp/bejaune_preview.html"
with open(html_path, "w") as f:
    f.write(html_content)

# Convertir en PDF avec wkhtmltopdf ou utiliser webkit
pdf_path = "/Users/sachamontel/Development/Jaune/preview_render.pdf"

try:
    # Essayer avec wkhtmltopdf si disponible
    result = subprocess.run(
        ["wkhtmltopdf", html_path, pdf_path],
        capture_output=True
    )
    if result.returncode == 0:
        print(f"✅ PDF généré avec succès: {pdf_path}")
except:
    pass

# Si wkhtmltopdf ne fonctionne pas, essayer avec macOS native
try:
    subprocess.run(
        ["webkithtml2pdf", html_path, pdf_path],
        capture_output=True
    )
    print(f"✅ PDF généré avec webkithtml2pdf: {pdf_path}")
except:
    print("⚠️  Aucun convertisseur HTML→PDF disponible")
    print(f"Fichier HTML créé à: {html_path}")
    print("Vous pouvez l'ouvrir dans un navigateur et imprimer en PDF")
