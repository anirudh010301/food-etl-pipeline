import os
import zipfile
from pathlib import Path
from dotenv import load_dotenv
from loguru import logger

# Load environment variables from .env file
load_dotenv()

# Set Kaggle credentials from .env
os.environ['KAGGLE_USERNAME'] = os.getenv('KAGGLE_USERNAME')
os.environ['KAGGLE_KEY'] = os.getenv('KAGGLE_KEY')

# Import kaggle after setting credentials
import kaggle

# Define paths
RAW_DATA_PATH = Path('data/raw')

def download_dataset():
    """Download the Fast Food dataset from Kaggle"""
    
    logger.info("Starting Kaggle dataset download...")
    
    # Dataset identifier from Kaggle URL
    dataset = "valeriacalderonn/fast-food-sales-orders-and-hr-dataset-20222024"
    
    # Download dataset
    kaggle.api.dataset_download_files(
        dataset,
        path=RAW_DATA_PATH,
        unzip=True
    )
    
    logger.success(f"Dataset downloaded successfully to {RAW_DATA_PATH}")

def verify_files():
    """Verify all expected files are downloaded"""
    
    logger.info("Verifying downloaded files...")
    
    # List all files in raw data folder
    files = list(RAW_DATA_PATH.glob('*'))
    
    if not files:
        logger.error("No files found in data/raw/")
        return False
    
    for file in files:
        size = file.stat().st_size / 1024  # Convert to KB
        logger.info(f"Found: {file.name} ({size:.2f} KB)")
    
    return True

if __name__ == "__main__":
    download_dataset()
    verify_files()