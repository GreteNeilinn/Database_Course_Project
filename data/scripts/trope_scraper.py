import pandas as pd
import os
import time
import random
import re
from tqdm import tqdm
from bs4 import BeautifulSoup

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager


# -------------------------
# CONFIG
# -------------------------

MOVIES_CSV = "list_movies.csv"
OUTPUT_TROPES = "tropes.csv"
OUTPUT_MOVIE_TROPES = "movie_tropes.csv"

TOTAL_TO_PROCESS = 1000     # process exactly 1000 movies
BATCH_SIZE = 100            # in batches of 100


# -------------------------
# LOAD MOVIES (LIMIT 1000)
# -------------------------
movies = pd.read_csv(MOVIES_CSV)
movies = movies[movies["link"].notna()].head(TOTAL_TO_PROCESS).reset_index(drop=True)

print(f"Loaded {len(movies)} movies (processing in batches of {BATCH_SIZE})")


# -------------------------
# LOAD EXISTING TROPE OUTPUT OR INIT EMPTY
# -------------------------
if os.path.exists(OUTPUT_TROPES):
    trope_df = pd.read_csv(OUTPUT_TROPES)
else:
    trope_df = pd.DataFrame(columns=["tropeid", "tropename"])

if os.path.exists(OUTPUT_MOVIE_TROPES):
    movie_tropes_df = pd.read_csv(OUTPUT_MOVIE_TROPES)
else:
    movie_tropes_df = pd.DataFrame(columns=["movie_id", "tropeid"])

# Create mapping from existing trope names → their IDs
trope_map = dict(zip(trope_df["tropename"], trope_df["tropeid"]))


# -------------------------
# SELENIUM SETUP
# -------------------------
chrome_options = Options()
chrome_options.add_argument("--disable-blink-features=AutomationControlled")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--disable-extensions")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--start-maximized")
chrome_options.add_argument("--remote-debugging-port=9222")
chrome_options.add_argument(
    "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
)

service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service, options=chrome_options)
actions = ActionChains(driver)


# -------------------------
# SCRAPER FUNCTION
# -------------------------
def scrape_tropes(url):
    try:
        driver.get(url)
        time.sleep(random.uniform(2, 4))

        # simulate scrolling
        for _ in range(random.randint(2, 5)):
            driver.execute_script("window.scrollBy(0, 300);")
            time.sleep(random.uniform(0.8, 1.5))

        html = driver.page_source
        soup = BeautifulSoup(html, "html.parser")

        article = soup.select_one("div#main-article")
        if not article:
            return []

        links = article.select("a[href*='/Main/']")
        tropes = [re.sub(".*/Main/", "", a["href"]) for a in links]

        return sorted(set(tropes))

    except Exception as e:
        print(f"Error scraping {url}: {e}")
        return []


# -------------------------
# PROCESS MOVIES IN BATCHES OF 100
# -------------------------
for batch_start in range(0, TOTAL_TO_PROCESS, BATCH_SIZE):

    batch = movies.iloc[batch_start:batch_start + BATCH_SIZE]
    print(f"\n=== Processing batch {batch_start//BATCH_SIZE + 1} "
          f"({len(batch)} movies) ===\n")

    batch_rows = []   # Temporary store for this batch

    for idx, row in tqdm(batch.iterrows(), total=len(batch)):
        movie_id = row["id"] if "id" in row else f"movie_{idx}"
        tropes = scrape_tropes(row["link"])

        for trope in tropes:

            # If trope is new → assign new ID
            if trope not in trope_map:
                trope_id = "tr" + str(len(trope_df) + 1).zfill(5)
                trope_df.loc[len(trope_df)] = [trope_id, trope]
                trope_map[trope] = trope_id

            # Add movie-trope pair
            batch_rows.append({
                "movie_id": movie_id,
                "tropeid": trope_map[trope]
            })

        time.sleep(random.uniform(2, 5))

    # Append batch rows to main results
    movie_tropes_df = pd.concat(
        [movie_tropes_df, pd.DataFrame(batch_rows)],
        ignore_index=True
    )

    # SAVE AFTER EACH BATCH
    trope_df.to_csv(OUTPUT_TROPES, index=False)
    movie_tropes_df.to_csv(OUTPUT_MOVIE_TROPES, index=False)

    print(f"Batch saved → Total tropes: {len(trope_df)}, "
          f"movie-trope pairs: {len(movie_tropes_df)}")


driver.quit()
print("\nDONE — 1000 movies processed in 10 batches of 100!")
