import csv
import random
from datetime import date

random.seed(42)

REGIONS = ["Northeast", "Southeast", "Midwest", "Southwest", "West"]
PRODUCT_LINES = ["Floor Tile", "Wall Tile", "Stone", "Mosaic"]

# Base monthly units per region — some regions naturally bigger than others
BASE_UNITS = {
    "Northeast":  1800,
    "Southeast":  2200,
    "Midwest":    1600,
    "Southwest":  2400,
    "West":       2000,
}

# Base price per product line
BASE_PRICE = {
    "Floor Tile": 42.00,
    "Wall Tile":  38.00,
    "Stone":      85.00,
    "Mosaic":     62.00,
}

rows = []

for year in range(2020, 2025):
    for month in range(1, 13):
        for region in REGIONS:
            for product in PRODUCT_LINES:
                # Add seasonality — construction peaks spring/summer
                season_factor = 1.0
                if month in [3, 4, 5, 6]:
                    season_factor = 1.15
                elif month in [11, 12, 1]:
                    season_factor = 0.85

                # Add a slow upward trend over the years
                trend_factor = 1 + (year - 2020) * 0.04

                # Add some noise
                noise = random.uniform(0.90, 1.10)

                units = int(BASE_UNITS[region] * season_factor * trend_factor * noise / 4)
                price = BASE_PRICE[product] * random.uniform(0.95, 1.05)
                revenue = round(units * price, 2)

                rows.append({
                    "region":       region,
                    "sale_month":   f"{year}-{str(month).zfill(2)}",
                    "product_line": product,
                    "units_sold":   units,
                    "revenue":      revenue,
                })

with open("data/regional_sales.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)

print(f"Generated {len(rows)} rows → data/regional_sales.csv")