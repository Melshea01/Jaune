import re

with open("lib/be_real_capture_page.dart","r") as f:
    text = f.read()

# Make sure imports are clean
if "import 'dart:io';" not in text:
    text = text.replace("import 'dart:ui' as ui;", "import 'dart:ui' as ui;\nimport 'dart:io';\nimport 'dart:typed_data';\nimport 'dart:async';")

# replace Widget _buildCompositionPreview() with the new signature
old_sig = """Widget _buildCompositionPreview() {"""
new_sig = """Widget _buildCompositionPreview({ui.Image? rearUiImage, ui.Image? frontUiImage}) {"""
if old_sig in text:
    text = text.replace(old_sig, new_sig)

# replace the background box
old_box = """          // Fond
          Container(
            width: screenWidth,
            height: previewHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.amber.shadeimport re

with open("lib/be_
 
with op       text = f.read()

# Make sure imports are clean
  
# Make sure imporn(
if "import 'dart:io's.camera_alt,
                size: 48,
      
# replace Widget _buildCompositionPreview() with the new signature
old_sig = """Widget _buildCompositionPreview() {"""
new_sig = """Widget _buiimaold_sig = ""dé
          if (rearUiImage != null || frontUiImage !new_sig = """Widget _buildCompositionPreview({ui.I sif old_sig in text:
    text = text.replace(old_sig, new_sig)

# replace the background box
old_bbo    text = text.reRa
# replace the background box
old_box = : RawImage(
                  im          Container(
        ag            width:               height: previewHei              decoration: BoxDecora                borderRadius: BorderRadr(              gradient: LinearGradient(
             ht           ight,
              decoration: BoxDecoration(
                borderRadi                colors: [Colors.amber.shade  
with open("lib/be_
 
with op       text = f.read(): A 
with op       tr,
 
# Make sure imports are cleent  
# Make sure imporn(
if "i  #  if "rs: [Colors.ambe                size: 48,
      00      
#           ),
    # rep  old_sig = """Widget _buildCompositionPreview() {"""
new_sig = """  new_sig = """Widget _buiima_alt,
                  s          if (rearUiImage != null || fronwh    text = text.replace(old_sig, new_sig)

# replace the background box
old_bbo    text = text.reRa
# replace the backgro
 
# replace the background box
old_bbo   rUiold_bbo    text = text.reRaPo# replace the backgroun top:old_box = : RawImage(
                         imWi        ag            width:           ne             ht           ight,
              decoration: BoxDecoration(
                borderRadi                colors: [Colors.amber.shade  
with open("lib/be_
 
rderRadius:              decoration: BoxD                  borderRadi              Cwith open("lib/be_
 
with op       text = f.read(): A 
with op       tRR 
with op       t    with op       tr,
 
# Radius.circu 
# Make sure im    # Make sure d: RawImage(
        if "i  #  if "rs:  f      00      
#           ),
    # rep  old_sig = ""   #           ) ),
             new_sig = """  new_sig = """Widget _buiima_alt,
             
                   s          if (rearUiImage !w 
# replace the background box
old_bbo    text = text.reRa
# replace the backgro
 
# replace the backgrnedold_bbo    text = text([\s\S]*?JAUNE[\s\S]*?\}\),\s*\),\s*\),\s*\),', '', text, fold_bbo   rUiold_bbo    tex)
                         imWi        ag       ") as f:
    f.write(text)
