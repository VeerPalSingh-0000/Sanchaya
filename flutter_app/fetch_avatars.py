import requests
import time

url = "https://api.jikan.moe/v4/characters?order_by=favorites&sort=desc&limit=25"
response = requests.get(url)
data = response.json()

avatars = []
for char in data.get('data', []):
    name = char['name']
    image_url = char['images']['jpg']['image_url']
    avatars.append({'name': name, 'url': image_url})

print("const _kDefaultAvatars = [")
for a in avatars:
    print(f"  {{'name': '{a['name']}', 'url': '{a['url']}'}},")
print("  {'name': 'None', 'url': ''},")
print("];")
