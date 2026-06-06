import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
from loguru import logger
import os

# Load environment variables
load_dotenv()

# Database connection
DB_URL = f"mysql+pymysql://{os.getenv('MYSQL_USER')}:{os.getenv('MYSQL_PASSWORD')}@{os.getenv('MYSQL_HOST')}:{os.getenv('MYSQL_PORT')}/{os.getenv('MYSQL_DATABASE')}"
engine = create_engine(DB_URL)

# Excel file path
FILE_PATH = 'data/raw/Bembos_Bases_de_Datos_2022_2024.xlsx'

# Column rename maps — Spanish to English
ORDERS_COLUMNS = {
    'ID_Pedido': 'order_id',
    'Fecha_Pedido': 'order_date',
    'Año': 'year',
    'Mes': 'month',
    'Trimestre': 'quarter',
    'FK_ID_Sede': 'branch_id',
    'Sede': 'branch_name',
    'FK_ID_Canal': 'channel_id',
    'Canal': 'channel_name',
    'FK_ID_Estado': 'status_id',
    'Estado_Pedido': 'order_status',
    'FK_ID_Producto': 'product_id',
    'Producto': 'product_name',
    'Cantidad': 'quantity',
    'Precio_Unitario_PEN': 'unit_price',
    'Descuento_Pct': 'discount_pct',
    'Subtotal_PEN': 'subtotal',
    'FK_ID_Empleado': 'employee_id',
    'FK_ID_MetodoPago': 'payment_method_id',
    'Metodo_Pago': 'payment_method',
    'Tiempo_Preparacion_Min': 'preparation_time_min',
    'KPI_Ticket_Promedio': 'kpi_avg_ticket',
    'KPI_Tiempo_Atencion_Min': 'kpi_service_time_min',
    'KPI_Tasa_Cancelacion': 'kpi_cancellation_rate'
}

SALES_COLUMNS = {
    'ID_Venta': 'sale_id',
    'Fecha_Venta': 'sale_date',
    'Año': 'year',
    'Mes': 'month',
    'Trimestre': 'quarter',
    'FK_ID_Pedido': 'order_id',
    'FK_ID_Sede': 'branch_id',
    'Sede': 'branch_name',
    'FK_ID_Canal': 'channel_id',
    'Canal': 'channel_name',
    'FK_ID_Producto': 'product_id',
    'Producto': 'product_name',
    'Cantidad_Vendida': 'quantity_sold',
    'Precio_Unitario_PEN': 'unit_price',
    'Descuento_Pct': 'discount_pct',
    'Ingreso_Bruto_PEN': 'gross_revenue',
    'Ingreso_Neto_PEN': 'net_revenue',
    'Costo_Produccion_PEN': 'production_cost',
    'FK_ID_MetodoPago': 'payment_method_id',
    'Metodo_Pago': 'payment_method',
    'KPI_Margen_Bruto_Pct': 'kpi_gross_margin_pct',
    'KPI_Ingreso_Neto_PEN': 'kpi_net_revenue',
    'KPI_Ticket_Promedio_PEN': 'kpi_avg_ticket'
}

EMPLOYEES_COLUMNS = {
    'ID_Empleado': 'employee_id',
    'Nombre': 'first_name',
    'Apellido': 'last_name',
    'ID_Sede': 'branch_id',
    'Sede': 'branch_name',
    'ID_Cargo': 'role_id',
    'Cargo': 'role_name',
    'ID_Turno': 'shift_id',
    'Turno': 'shift_name',
    'Fecha_Ingreso': 'hire_date',
    'Salario_Base_PEN': 'base_salary',
    'Años_Experiencia': 'years_experience',
    'Dias_Ausentismo_Anual': 'annual_absence_days',
    'Pedidos_Atendidos': 'orders_attended',
    'Calificacion_Cliente': 'customer_rating',
    'KPI_Productividad': 'kpi_productivity',
    'KPI_Satisfaccion': 'kpi_satisfaction',
    'KPI_Asistencia_Pct': 'kpi_attendance_pct',
    'FK_ID_Sede': 'fk_branch_id'
}

def read_sheet(sheet_name):
    """Read sheet skipping title row"""
    # header=1 skips the title row and uses row 1 as column names
    df = pd.read_excel(FILE_PATH, sheet_name=sheet_name, header=1)
    # Drop the KPI legend row (first row after header)
    df = df.iloc[1:].reset_index(drop=True)
    return df

def load_orders():
    """Load orders sheet into stg_orders"""
    logger.info("Loading orders into stg_orders...")

    df = read_sheet('PEDIDOS')

    # Rename columns to English
    df = df.rename(columns=ORDERS_COLUMNS)

    # Drop rows where order_id is null
    df = df.dropna(subset=['order_id'])

    # Select only the columns we need
    df = df[list(ORDERS_COLUMNS.values())]

    # Load into MySQL
    df.to_sql('stg_orders', engine, if_exists='append', index=False)

    logger.success(f"Loaded {len(df)} rows into stg_orders")

def load_sales():
    """Load sales sheet into stg_sales"""
    logger.info("Loading sales into stg_sales...")

    df = read_sheet('VENTAS')

    # Rename columns to English
    df = df.rename(columns=SALES_COLUMNS)

    # Drop rows where sale_id is null
    df = df.dropna(subset=['sale_id'])

    # Select only the columns we need
    df = df[list(SALES_COLUMNS.values())]

    # Load into MySQL
    df.to_sql('stg_sales', engine, if_exists='append', index=False)

    logger.success(f"Loaded {len(df)} rows into stg_sales")

def load_employees():
    """Load employees sheet into stg_employees"""
    logger.info("Loading employees into stg_employees...")

    df = read_sheet('EMPLEADOS')

    # Rename columns to English
    df = df.rename(columns=EMPLOYEES_COLUMNS)

    # Drop rows where employee_id is null
    df = df.dropna(subset=['employee_id'])

    # Drop duplicate fk_branch_id column
    df = df.drop(columns=['fk_branch_id'])

    # Select only the columns we need
    cols = [c for c in EMPLOYEES_COLUMNS.values() if c != 'fk_branch_id']
    df = df[cols]

    # Load into MySQL
    df.to_sql('stg_employees', engine, if_exists='append', index=False)

    logger.success(f"Loaded {len(df)} rows into stg_employees")

if __name__ == "__main__":
    logger.info("Starting staging load...")
    load_orders()
    load_sales()
    load_employees()
    logger.success("Staging load complete!")