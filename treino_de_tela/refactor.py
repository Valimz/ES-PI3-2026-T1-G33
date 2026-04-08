import os
import re

base_dir = r"c:/Users/User/Desktop/ES-PI3-2026-T1-G33/treino_de_tela/lib"

os.makedirs(os.path.join(base_dir, "pages"), exist_ok=True)
os.makedirs(os.path.join(base_dir, "theme"), exist_ok=True)

pages = [
    "explore_page.dart",
    "home_page.dart",
    "login_page.dart",
    "register_page.dart",
    "transaction_details_page.dart",
    "wallet_page.dart"
]

for p in pages:
    src = os.path.join(base_dir, p)
    dst = os.path.join(base_dir, "pages", p)
    if os.path.exists(src):
        os.rename(src, dst)

app_colors_code = """import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFF4ECCA3);
  static const Color background = Color(0xFFF7F9FC);
  static const Color textBody = Color(0xFF4A4A4A);
}
"""
with open(os.path.join(base_dir, "theme", "app_colors.dart"), "w", encoding="utf-8") as f:
    f.write(app_colors_code)

main_dart_path = os.path.join(base_dir, "main.dart")
with open(main_dart_path, "r", encoding="utf-8") as f:
    main_dart = f.read()

main_dart = re.sub(r"class AppColors \{[\s\S]*?\}\n\n", "", main_dart)
main_dart = main_dart.replace("import 'package:treino_de_tela/", "import 'package:treino_de_tela/pages/")
main_dart = "import 'package:treino_de_tela/theme/app_colors.dart';\n" + main_dart

with open(main_dart_path, "w", encoding="utf-8") as f:
    f.write(main_dart)

def update_imports(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    content = re.sub(r"import 'main\.dart';.*?\n", "import 'package:treino_de_tela/theme/app_colors.dart';\n", content)
    content = re.sub(r"import '../main\.dart';.*?\n", "import 'package:treino_de_tela/theme/app_colors.dart';\n", content)
    
    for p in pages:
        content = re.sub(rf"import '{p}';.*?\n", f"import 'package:treino_de_tela/pages/{p}';\n", content)
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

for p in pages:
    page_path = os.path.join(base_dir, "pages", p)
    if os.path.exists(page_path):
        update_imports(page_path)

print("Architecture refactored successfully.")
