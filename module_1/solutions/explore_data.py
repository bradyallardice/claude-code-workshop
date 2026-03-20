"""Quick script to load and inspect the presidential election data."""
import pandas as pd

df = pd.read_csv("demo_data/countypres_2000-2024.csv")
print(df.head())
print(df.shape)
print(df.columns.tolist())

# Let's do some basic exploration of the data.

# How many unique candidates are there?
unique_candidates = df["candidate"].nunique()

print(f"There are {unique_candidates} unique candidates in the dataset.")

# How many unique parties are there?
unique_parties = df["party"].nunique()

# What are the vote shares across different parties and elections in the dataset?

print(f"There are {unique_parties} unique parties in the dataset.")



