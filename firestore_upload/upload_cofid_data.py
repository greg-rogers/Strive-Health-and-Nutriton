import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore

# Load Firebase credentials
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Load the Excel file
file_path = "McCance_Widdowsons_Composition_of_Foods_Integrated_Dataset_2021..xlsx"
sheet_name = "1.3 Proximates"  
df = pd.read_excel(file_path, sheet_name=sheet_name)

# Keep a few key columns (update these based on actual column headers)
columns_to_keep = [
    "Food Name", "Energy (kcal) (kcal)", "Protein (g)", "Fat (g)", "Carbohydrate (g)",
    "AOAC fibre (g)"
]
df = df[columns_to_keep].dropna(subset=["Food Name"])  # Filter out rows with no name

# Upload to Firestore
for index, row in df.iterrows():
    food_doc = {
        "name": row["Food Name"],
        "calories": row["Energy (kcal) (kcal)"],
        "protein": row["Protein (g)"],
        "fat": row["Fat (g)"],
        "carbs": row["Carbohydrate (g)"],
        "fibre": row["AOAC fibre (g)"]
        
    }
    db.collection("foods").add(food_doc)

print("Upload complete.")
