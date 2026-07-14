import re

text = """
static const Color foo = Colors.red;
const Icon(Icons.abc);
const Text("hello");
const EdgeInsets.all(8);
const [ 1, 2, 3 ];
const { 'a': 1 };
"""

new_text = re.sub(r"(?<!static\s)\bconst\s+(?=[A-Z]|\[|\{)", "", text)
print(new_text)
