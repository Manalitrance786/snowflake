//Create Stage//
create stage my_stage
URL ="s3://snowflake-db-tutorial-manali/instacart/"
CREDENTIALS = (AWS_KEY_ID = '********************' AWS_SECRET_KEY = '**********************************');

//Create file format//
create or replace file format csv_file_format
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

//create table Aisles//

CREATE or REPLACE TABLE Aisles(
aisle_id integer PRIMARY KEY,
aisle varchar);

//create table Departments//

CREATE or REPLACE TABLE Departments(
    department_id INTEGER PRIMARY KEY,
    department VARCHAR);

COPY INTO Aisles
FROM @my_stage/aisles.csv
FILE_FORMAT = (FORMAT_NAME='csv_file_format');

select * from Aisles;
select * from Departments;

COPY INTO Departments
FROM @my_stage/departments.csv
FILE_FORMAT = (FORMAT_NAME='csv_file_format');


CREATE OR REPLACE TABLE Products(
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR,
    aisle_id INTEGER,
    department_id INTEGER);

COPY INTO Products
FROM @my_stage/products.csv
FILE_FORMAT = (FORMAT_NAME='csv_file_format');

select * from orders;


CREATE OR REPLACE TABLE orders (
        order_id INTEGER PRIMARY KEY,
        user_id INTEGER,
        eval_set STRING,
        order_number INTEGER,
        order_dow INTEGER,
        order_hour_of_day INTEGER,
        days_since_prior_order INTEGER
    );

COPY INTO orders (order_id, user_id, eval_set, order_number, order_dow, order_hour_of_day, days_since_prior_order)
FROM @my_stage/orders.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_file_format');


CREATE OR REPLACE TABLE order_products (
        order_id INTEGER,
        product_id INTEGER,
        add_to_cart_order INTEGER,
        reordered INTEGER,
        PRIMARY KEY (order_id, product_id)
    );
    
COPY INTO order_products (order_id, product_id, add_to_cart_order, reordered)
FROM @my_stage/order_products.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_file_format');

select * from order_products;

create or replace table dim_users as(
    select user_id from Orders);

create or replace table dim_departments as(
    select
        department_id,
        department    
    from 
        Departments
);

select * from dim_departments;

create or replace table dim_aisles as(
    select
        aisle_id,
        aisle    
    from 
        Aisles
);


create or replace table dim_Products as(
    select
        product_id,
        product_name    
    from 
        Products
);

create or replace table dim_Orders as(
    select
        order_id,
        order_number,
        order_dow,
        order_hour_of_day,
        days_since_prior_order
    from 
        Orders
);


create or replace table fact_order_products as (
    select
        op.order_id,
        op.product_id,
        p.aisle_id,
        p.department_id,
        o.user_id,
        op.add_to_cart_order,
        op.reordered
    from
       order_products op
    JOIN
        orders o
    ON
        op.order_id = o.order_id
    join
        Products p
    ON op.product_id = p.product_id
       
);

select * from fact_order_products;

'''top 3 departments with maximum orders'''
select
    d.department,
    count(f.order_id) as total_orders    
from 
    fact_order_products f
JOIN
    departments d
ON f.department_id = d.department_id
group by d.department
order by total_orders desc
LIMIT 3;

'''top 5 products ordered'''
select 
    p.product_name,
    count(f.order_id) as Orders
from 
    fact_order_products f
JOIN
    dim_products p
on f.product_id = p.product_id
join
    dim_orders o
on f.order_id = o.order_id
group by p.product_name
order by Orders desc
LIMIT 5;
