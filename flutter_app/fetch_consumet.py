import requests

try:
    print('Fetching Consumet...')
    r = requests.get('https://api.consumet.org/meta/anilist/episodes/21')
    r.raise_for_status()
    data = r.json()
    print(f"Found {len(data)} episodes")
except Exception as e:
    print(f'Error: {e}')
