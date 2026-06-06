import pandas as pd
from loguru import logger

FILE_PATH = 'data/raw/Bembos_Bases_de_Datos_2022_2024.xlsx'

def read_sheet(sheet_name):
    """Read sheet correctly — skip title row, use row 1 as header"""
    return pd.read_excel(FILE_PATH, sheet_name=sheet_name, header=1)

def explore_sheet(df, sheet_name):
    """Print full exploration of a sheet"""
    logger.info(f"\n{'='*60}")
    logger.info(f"Sheet: {sheet_name}")
    logger.info(f"Rows: {len(df)}")
    logger.info(f"Columns: {list(df.columns)}")
    logger.info(f"\nData Types:\n{df.dtypes}")
    logger.info(f"\nNull counts:\n{df.isnull().sum()}")
    logger.info(f"\nFirst 3 rows:\n{df.head(3)}")

def explore_all():
    sheets = ['PEDIDOS', 'VENTAS', 'EMPLEADOS']
    for sheet in sheets:
        df = read_sheet(sheet)
        explore_sheet(df, sheet)

if __name__ == "__main__":
    explore_all()