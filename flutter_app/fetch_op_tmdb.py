import requests
import json
import os

tmdb_key = 'd60e665c617655185db02ee381c7bd0a'
all_episodes = []

try:
    print('Fetching One Piece (TMDB ID 37854)...')
    r = requests.get(f'https://api.themoviedb.org/3/tv/37854?api_key={tmdb_key}')
    r.raise_for_status()
    data = r.json()
    seasons = data['seasons']
    total_episodes = 0
    
    for season in seasons:
        s_num = season['season_number']
        if s_num == 0: continue
        print(f'Fetching season {s_num}...')
        sr = requests.get(f'https://api.themoviedb.org/3/tv/37854/season/{s_num}?api_key={tmdb_key}')
        sr.raise_for_status()
        s_data = sr.json()
        for ep in s_data['episodes']:
            total_episodes += 1
            all_episodes.append({
                'mal_id': total_episodes,
                'title': ep['name'],
                'title_japanese': '',
                'aired': ep['air_date'] + 'T00:00:00+00:00' if ep.get('air_date') else None,
                'filler': False,
                'recap': False,
                'synopsis': ep['overview']
            })
            
    print(f'Total episodes: {total_episodes}')
    with open('assets/data/one_piece_episodes.json', 'w') as f:
        json.dump(all_episodes, f)
    print('Done!')
except Exception as e:
    print(f'Error: {e}')
