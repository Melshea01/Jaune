#!/usr/bin/env python3
"""
Génère un PDF de prévisualisation du montage photo BEJAUNE
"""

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.colors import Color, HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from PIL import Image, ImageDraw
import io
import math

# Dimensions de la prévisualisation
PREVIEW_WIDTH = 300
PREVIEW_HEIGHT = 400
HEALTH_PERCENT = 0.75  # À modifier pour tester

def create_preview_image():
    """Crée l'image de prévisualisation"""
    # Créer une image avec dégradé
    img = Image.new('RGB', (PREVIEW_WIDTH, PREVIEW_HEIGHT), color='white')
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # Fond dégradé (orange/amber)
    for y in range(PREVIEW_HEIGHT):
        # Gradient du orange clair au orange foncé
        r = int(218 + (139 - 218) * (y / PREVIEW_HEIGHT))
        g = int(165 + (69 - 165) * (y / PREVIEW_HEIGHT))
        b = int(32 + (19 - 32) * (y / PREVIEW_HEIGHT))
        draw.line([(0, y), (PREVIEW_WIDTH, y)], fill=(r, g, b, 255))
    
    # Zone PV en haut à droite (bleu)
    pv_size = int(PREVIEW_WIDTH * 0.35)
    pv_x = PREVIEW_WIDTH - pv_size - 24
    pv_y = 24
    
    # Fond bleu du PV
    for py in range(pv_size):
        for px in range(pv_size):
            progress = (px + py) / (pv_size * 2)
            r = int(100 + (70 - 100) * progress)
            g = int(200 + (150 - 200) * progress)
            b = int(255)
            draw.point((pv_x + px, pv_y + py), fill=(r, g, b, 255))
    
    # Bordure noire du PV
    draw.rectangle(
        [(pv_x, pv_y), (pv_x + pv_size, pv_y + pv_size)],
        outline=(0, 0, 0, 255),
        width=4
    )
    
    # Texte "PV" et nombre dans la zone bleue
    # (simplement un placeholder visuel)
    draw.text((pv_x + 20, pv_y + 30), "PV", fill=(200, 200, 200, 200))
    draw.text((pv_x + 30, pv_y + 50), "75", fill=(255, 255, 255, 255))
    draw.text((pv_x + 35, pv_y + 80), "🍋", fill=(255, 255, 255, 255))
    
    # Barre de santé (centré, en bas)
    bar_width = int(PREVIEW_WIDTH * 0.35)
    bar_height = 16
    bar_x = (PREVIEW_WIDTH - bar_width) // 2
    bar_y = PREVIEW_HEIGHT - 100
    
    # Fond givré blanc
    draw.rectangle(
        [(bar_x, bar_y), (bar_x + bar_width, bar_y + bar_height)],
        fill=(200, 200, 200, 150),
        outline=(255, 255, 255, 100),
        width=1
    )
    
    # Remplissage coloré (vert car > 0.6)
    fill_width = int(bar_width * HEALTH_PERCENT)
    draw.rectangle(
        [(bar_x, bar_y), (bar_x + fill_width, bar_y + bar_height)],
        fill=(67, 233, 123, 200)
    )
    
    # Texte "JAUNE" en bas
    draw.text(
        (PREVIEW_WIDTH // 2 - 40, PREVIEW_HEIGHT - 40),
        "JAUNE",
        fill=(30, 30, 30, 255)
    )
    
    return img

def generate_pdf():
    """Génère le PDF"""
    # Créer l'image de prévisualisation
    preview_img = create_preview_image()
    
    # Créer le PDF
    c = canvas.Canvas("/Users/sachamontel/Development/Jaune/preview_render.pdf", pagesize=letter)
    width, height = letter
    
    # Titre
    c.setFont("Helvetica-Bold", 24)
    c.drawString(50, height - 50, "BEJAUNE - Rendu du Montage Photo")
    
    # Sous-titre
    c.setFont("Helvetica", 12)
    c.drawString(50, height - 75, f"PV: 75% | Aspect Ratio: 9/12")
    
    # Sauvegarder l'image en bytes
    img_bytes = io.BytesIO()
    preview_img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    # Ajouter l'image au PDF
    preview_img.save("/tmp/temp_preview.png")
    c.drawImage("/tmp/temp_preview.png", 50, height - 550, width=300, height=400)
    
    # Informations
    c.setFont("Helvetica", 10)
    c.drawString(50, 100, "✓ Haut-droite: Zone PV avec avatar 🍋")
    c.drawString(50, 85, "✓ Bas centré: Texte 'JAUNE'")
    c.drawString(50, 70, "✓ Barre de santé centrée (au-dessus de JAUNE)")
    c.drawString(50, 55, "✓ Pas de carte de message")
    
    c.save()
    print("✅ PDF généré: preview_render.pdf")

if __name__ == "__main__":
    generate_pdf()
