import requests
import json

try:
    print('Fetching Kitsu One Piece...')
    # One Piece kitsu ID is 11
    r = requests.get('https://kitsu.io/api/edge/anime/11/episodes?page[limit]=20')
    r.raise_for_status()
    data = r.json()
    print(f"Found {len(data['data'])} episodes in page 1")
    for ep in data['data']:
        print(f"Ep {ep['attributes']['number']}: {ep['attributes']['canonicalTitle']}")
except Exception as e:
    print(f'Error: {e}')
