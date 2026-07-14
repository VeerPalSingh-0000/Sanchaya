import os

path = "lib/widgets/episode_tracker_widget.dart"
with open(path, "r") as f:
    content = f.read()

# Replace _buildButton(icon: with _buildButton(context, icon:
content = content.replace("_buildButton(icon:", "_buildButton(context, icon:")

with open(path, "w") as f:
    f.write(content)
