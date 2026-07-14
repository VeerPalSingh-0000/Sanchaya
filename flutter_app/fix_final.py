import re

with open("lib/screens/settings_screen.dart", "r") as f:
    content = f.read()

if "import '../config/theme.dart';" not in content:
    content = re.sub(r"^(import .*;\n)", r"\1import '../config/theme.dart';\n", content, count=1, flags=re.MULTILINE)

with open("lib/screens/settings_screen.dart", "w") as f:
    f.write(content)

with open("lib/widgets/episode_tracker_widget.dart", "r") as f:
    content = f.read()

content = re.sub(r"_buildButton\(\s*icon:", "_buildButton(context, icon:", content)

with open("lib/widgets/episode_tracker_widget.dart", "w") as f:
    f.write(content)
