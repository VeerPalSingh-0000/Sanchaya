import os
import time
import requests
import urllib.parse

TMDB_API_KEY = 'd60e665c617655185db02ee381c7bd0a'
missing = [
    ("captain_america", "Chris Evans"),
    ("daenerys", "Emilia Clarke"),
    ("darth_vader", "James Earl Jones"), # or David Prowse
    ("deadpool", "Ryan Reynolds"),
    ("harry_potter", "Daniel Radcliffe"),
    ("indiana_jones", "Harrison Ford"),
    ("jack_sparrow", "Johnny Depp"),
    ("john_wick", "Keanu Reeves"),
    ("sheldon_cooper", "Jim Parsons"),
    ("sherlock_holmes", "Benedict Cumberbatch"),
    ("spider_man", "Tom Holland"),
    ("superman", "Henry Cavill"),
    ("the_joker", "Heath Ledger"),
    ("wolverine", "Hugh Jackman")
]

headers = {'User-Agent': 'Mozilla/5.0'}
for filename, actor in missing:
    url = f"https://api.themoviedb.org/3/search/person?api_key={TMDB_API_KEY}&query={urllib.parse.quote(actor)}"
    try:
        res = requests.get(url, headers=headers).json()
        if res.get('results') and len(res['results']) > 0:
            profile_path = res['results'][0].get('profile_path')
            if profile_path:
                img_url = f"https://image.tmdb.org/t/p/w500{profile_path}"
                img_data = requests.get(img_url, headers=headers).content
                with open(f"assets/avatar/{filename}.jpg", "wb") as f:
                    f.write(img_data)
                print(f"Downloaded {filename}.jpg")
    except Exception as e:
        print(f"Error {filename}: {e}")
    time.sleep(0.5)

print("Done missing avatars")
