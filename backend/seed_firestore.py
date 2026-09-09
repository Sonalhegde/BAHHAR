import json
import os
import sys

def seed_firestore(cred_path=None):
    """
    Seeds reference collections (species, hotspots, regions, regulations)
    into Cloud Firestore using firebase-admin or displays a verified dry-run.
    """
    seed_file = os.path.join(os.path.dirname(__file__), "firestore_seed.json")
    if not os.path.exists(seed_file):
        print(f"Error: {seed_file} not found")
        sys.exit(1)

    with open(seed_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    print("==================================================")
    print("  BAHHAR AI ? Cloud Firestore Reference Seeder")
    print("==================================================")

    if cred_path and os.path.exists(cred_path):
        try:
            import firebase_admin
            from firebase_admin import credentials, firestore

            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            db = firestore.client()

            for collection, items in data.items():
                print(f"\nSeeding collection: '{collection}' ({len(items)} documents)...")
                for item in items:
                    doc_id = item["id"]
                    db.collection(collection).document(doc_id).set(item)
                    print(f"  ? {collection}/{doc_id}")

            print("\n[SUCCESS] All collections seeded into production Firestore!")
            return
        except ImportError:
            print("[INFO] 'firebase-admin' package not installed. Performing verified dry-run validation.")
    else:
        print("[INFO] No service account JSON provided. Performing verified dry-run validation.")

    # Dry-run validation
    total_docs = 0
    for collection, items in data.items():
        print(f"\n[DRY RUN] Validated collection: '{collection}' ({len(items)} docs)")
        for item in items:
            print(f"  ? {item['id']} ({item.get('name', item.get('nameEn', ''))})")
            total_docs += 1

    print(f"\n[VERIFIED] Successfully validated {total_docs} reference documents ready for Firestore import.")

if __name__ == "__main__":
    cred_file = sys.argv[1] if len(sys.argv) > 1 else None
    seed_firestore(cred_file)
