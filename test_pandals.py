import sys
import traceback
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.append('../puja24_backend')
from config import DATABASE_URL
from crud.place import get_pandals

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

try:
    get_pandals(db=db)
    print("Success")
except Exception as e:
    traceback.print_exc()
