"""Quick script to load and inspect the presidential election data."""
import pandas as pd

df = pd.read_csv("demo_data/countypres_2000-2024.csv")
print(df.head())
print(df.shape)
print(df.columns.tolist())

# 
