import csv

TROPES_FILE = "tropes.csv"
LIST_TROPES_FILE = "list_tropes.csv"
OUTPUT_FILE = "tropes_updated.csv"

def clean(value: str) -> str:
    """Strip whitespace and surrounding quotes."""
    if value is None:
        return ""
    return value.strip().strip('"').strip("'").strip()

def load_list_tropes(path):
    """
    Load list_tropes.csv into a lookup:
      LOWERCASE(tropelink) → correct tropename
    """
    lookup = {}
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            tropelink = clean(row["tropelink"]).lower()
            tropename = clean(row["tropename"])
            lookup[tropelink] = tropename
    return lookup


def update_tropes(tropes_path, lookup, output_path):
    """
    Replace tropename in tropes.csv by matching the lowercase version
    to list_tropes.csv.tropelink. Write new names wrapped in quotes.
    """
    with open(tropes_path, "r", encoding="utf-8") as fin, \
         open(output_path, "w", encoding="utf-8", newline="") as fout:

        reader = csv.DictReader(fin)
        fieldnames = reader.fieldnames
        writer = csv.DictWriter(fout, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()

        for row in reader:
            old_name_raw = row["tropename"]
            old_clean = clean(old_name_raw).lower()

            if old_clean in lookup:
                new_name = lookup[old_clean]
                row["tropename"] = new_name
            else:
                print(f"[WARN] No match found for '{old_name_raw}'. Keeping original.")
                # Keep original but cleaned (or raw depending on preference)
                row["tropename"] = clean(old_name_raw)

            writer.writerow(row)


def main():
    print("Loading list_tropes.csv...")
    lookup = load_list_tropes(LIST_TROPES_FILE)
    print(f"Loaded {len(lookup)} trope mappings.")

    print("Updating tropes.csv...")
    update_tropes(TROPES_FILE, lookup, OUTPUT_FILE)

    print(f"Done! Updated file written to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
