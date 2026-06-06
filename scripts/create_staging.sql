-- ============================================================
-- STAGING LAYER
-- Raw data landing zone -- no transformation, just load
-- One null/dirty row will be handled in Python before load
-- ============================================================

CREATE DATABASE IF NOT EXISTS food_etl;
USE food_etl;

-- ----------------------------------------
-- Staging: Orders (PEDIDOS)
-- ----------------------------------------
DROP TABLE IF EXISTS stg_orders;
CREATE TABLE stg_orders (
    order_id                VARCHAR(20),
    order_date              VARCHAR(20),
    year                    INT,
    month                   INT,
    quarter                 INT,
    branch_id               INT,
    branch_name             VARCHAR(100),
    channel_id              INT,
    channel_name            VARCHAR(100),
    status_id               INT,
    order_status            VARCHAR(100),
    product_id              INT,
    product_name            VARCHAR(200),
    quantity                INT,
    unit_price              DECIMAL(10,2),
    discount_pct            DECIMAL(5,2),
    subtotal                DECIMAL(10,2),
    employee_id             INT,
    payment_method_id       INT,
    payment_method          VARCHAR(100),
    preparation_time_min    INT,
    kpi_avg_ticket          DECIMAL(10,2),
    kpi_service_time_min    DECIMAL(10,2),
    kpi_cancellation_rate   DECIMAL(5,2),
    loaded_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------
-- Staging: Sales (VENTAS)
-- ----------------------------------------
DROP TABLE IF EXISTS stg_sales;
CREATE TABLE stg_sales (
    sale_id                 VARCHAR(20),
    sale_date               VARCHAR(20),
    year                    INT,
    month                   INT,
    quarter                 INT,
    order_id                VARCHAR(20),
    branch_id               INT,
    branch_name             VARCHAR(100),
    channel_id              INT,
    channel_name            VARCHAR(100),
    product_id              INT,
    product_name            VARCHAR(200),
    quantity_sold           INT,
    unit_price              DECIMAL(10,2),
    discount_pct            DECIMAL(5,2),
    gross_revenue           DECIMAL(10,2),
    net_revenue             DECIMAL(10,2),
    production_cost         DECIMAL(10,2),
    payment_method_id       INT,
    payment_method          VARCHAR(100),
    kpi_gross_margin_pct    DECIMAL(5,2),
    kpi_net_revenue         DECIMAL(10,2),
    kpi_avg_ticket          DECIMAL(10,2),
    loaded_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------
-- Staging: Employees (EMPLEADOS)
-- ----------------------------------------
DROP TABLE IF EXISTS stg_employees;
CREATE TABLE stg_employees (
    employee_id             VARCHAR(20),
    first_name              VARCHAR(100),
    last_name               VARCHAR(100),
    branch_id               INT,
    branch_name             VARCHAR(100),
    role_id                 INT,
    role_name               VARCHAR(100),
    shift_id                INT,
    shift_name              VARCHAR(100),
    hire_date               VARCHAR(20),
    base_salary             DECIMAL(10,2),
    years_experience        DECIMAL(5,2),
    annual_absence_days     DECIMAL(5,2),
    orders_attended         INT,
    customer_rating         DECIMAL(3,2),
    kpi_productivity        DECIMAL(10,2),
    kpi_satisfaction        DECIMAL(3,2),
    kpi_attendance_pct      DECIMAL(5,2),
    loaded_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);