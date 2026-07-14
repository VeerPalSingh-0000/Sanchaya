import os
import re
import subprocess

target_dir = "lib"
replace_pattern = re.compile(r"AppTheme\.(background|surface|surfaceLight|primary|primaryLight|secondary|textMain|textMuted|textSubtle|divider|error|success|warning)")

for root, _, files in os.walk(target_dir):
    for file in files:
        if not file.endswith(".dart"): continue
        path = os.path.join(root, file)
        if "theme.dart" in path or "theme_extension.dart" in path:
            continue
            
        with open(path, "r") as f:
            content = f.read()
            
        if replace_pattern.search(content):
            new_content = replace_pattern.sub(r"context.colors.\1", content)
            
            new_content = re.sub(r"(?<!static )\bconst\s+(?=[A-Z]|\[|\{)", "", new_content)
            
            import_statement = "import 'package:flutter_app/config/theme_extension.dart';\n"
            if import_statement not in new_content:
                new_content = re.sub(r"^(import .*;\n)", r"\1" + import_statement, new_content, count=1, flags=re.MULTILINE)
            
            with open(path, "w") as f:
                f.write(new_content)

print("Replacement complete.")
