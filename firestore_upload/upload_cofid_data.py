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

df = df.drop_duplicates(subset=["Food Name"])

# Upload to Firestore
for index, row in df.iterrows():
    food_name = row["Food Name"]
    if pd.isna(food_name) or not str(food_name).strip():
        continue 

    food_name = str(row["Food Name"]).strip()
    doc_id = food_name.lower().replace("/", "_").replace(" ", "_")[:100]
    if not doc_id:
        continue

    food_doc = {
        "name": row["Food Name"],
        "name_lower": food_name.lower(),
        "calories": row["Energy (kcal) (kcal)"],
        "protein": row["Protein (g)"],
        "fat": row["Fat (g)"],
        "carbs": row["Carbohydrate (g)"],
        "fibre": row["AOAC fibre (g)"] if pd.notna(row["AOAC fibre (g)"]) else None,
        
    }
    db.collection("foods").document(doc_id).set(food_doc)

print("Upload complete.")
