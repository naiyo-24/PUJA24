import sys
import os

# Ensure the backend directory is in the path
backend_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../puja24_backend'))
sys.path.insert(0, backend_path)

from database import SessionLocal
from models.place import Place, PlaceType

def seed_pandals():
    db = SessionLocal()
    
    pandals = [
        {
            "name": "Sreebhumi Sporting Club",
            "type": PlaceType.PANDAL,
            "zone": "Salt Lake",
            "address": "Lake Town, Kolkata",
            "avg_rating": 4.9,
            "total_reviews": 1500,
            "is_popular": True,
            "location_wkt": "POINT(88.3995 22.5975)", # lon lat
            "metadata": {
                "theme2026": "Vatican City Replica",
                "queueTimeMins": 120,
                "crowdStatus": "High",
                "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/3/3a/Sreebhumi_Sporting_Club_Durga_Puja_Pandal_2022.jpg",
                "idolArtist": "Sanatan Dinda",
                "pandalDesigner": "Romeo Hazra",
                "amenities": ["VIP Gate", "Food Stalls", "Medical Camp"],
                "nearestMetro": "Belgachia",
                "nearestBusStop": "Lake Town"
            }
        },
        {
            "name": "College Square Sarbojanin",
            "type": PlaceType.PANDAL,
            "zone": "Central",
            "address": "College Square, Kolkata",
            "avg_rating": 4.8,
            "total_reviews": 1200,
            "is_popular": True,
            "location_wkt": "POINT(88.3639 22.5726)",
            "metadata": {
                "theme2026": "Traditional Lightings",
                "queueTimeMins": 45,
                "crowdStatus": "Moderate",
                "imageUrl": "https://images.unsplash.com/photo-1599839619722-39751411ea63?q=80&w=600&auto=format&fit=crop",
                "idolArtist": "Bhabatosh Sutar",
                "pandalDesigner": "Traditional Decorators",
                "amenities": ["Food Stalls", "Drinking Water"],
                "nearestMetro": "Central",
                "nearestBusStop": "College Square",
                "nearestCafe": "Indian Coffee House (500m)",
                "nearestHospital": "Medical College Hospital (800m)",
                "payAndUseToilet": "Near College Square Gate (100m)"
            }
        },
        {
            "name": "Bagbazar Sarbojonin",
            "type": PlaceType.PANDAL,
            "zone": "North Kolkata",
            "address": "Bagbazar, Kolkata",
            "avg_rating": 4.9,
            "total_reviews": 2100,
            "is_popular": True,
            "location_wkt": "POINT(88.3712 22.6025)",
            "metadata": {
                "theme2026": "Eksala Protima (Traditional)",
                "queueTimeMins": 60,
                "crowdStatus": "High",
                "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/4/4e/Bagbazar_Sarbojanin_Durga_Puja_2019.jpg",
                "idolArtist": "Traditional",
                "pandalDesigner": "Traditional",
                "amenities": ["Fair", "Food Stalls"],
                "nearestMetro": "Shyambazar",
                "nearestBusStop": "Bagbazar"
            }
        },
        {
            "name": "Suruchi Sangha",
            "type": PlaceType.PANDAL,
            "zone": "South Kolkata",
            "address": "New Alipore, Kolkata",
            "avg_rating": 4.8,
            "total_reviews": 1300,
            "is_popular": True,
            "location_wkt": "POINT(88.3297 22.5186)",
            "metadata": {
                "theme2026": "Global Peace",
                "queueTimeMins": 90,
                "crowdStatus": "High",
                "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/2/23/Suruchi_Sangha_Durga_Puja_Pandal_2016.jpg",
                "idolArtist": "Bhabatosh Sutar",
                "pandalDesigner": "Theme Decorators",
                "amenities": ["VIP Gate", "First Aid"],
                "nearestMetro": "Rabindra Sarobar",
                "nearestBusStop": "New Alipore"
            }
        }
    ]

    for p in pandals:
        # Check if already exists
        existing = db.query(Place).filter(Place.name == p["name"]).first()
        if existing:
            existing.place_metadata = p["metadata"]
            print(f"Updated metadata for {p['name']}")
        else:
            new_place = Place(
                name=p["name"],
                type=p["type"],
                zone=p["zone"],
                address=p["address"],
                avg_rating=p["avg_rating"],
                total_reviews=p["total_reviews"],
                is_popular=p["is_popular"],
                location=p["location_wkt"],
                place_metadata=p["metadata"]
            )
            db.add(new_place)
            print(f"Added {p['name']}")
            
    db.commit()
    db.close()
    print("Database seeding completed.")

if __name__ == "__main__":
    seed_pandals()
