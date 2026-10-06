# SALES_GROWTH_MONITOR

📊 SALES GROWTH MONITOR
An end-to-end data analytics project evaluating e-commerce sales performance, customer behavior, and profitability using SQL and Tableau.

🎯 Business Problem & Objectives
Management needed a centralized way to track critical Key Performance Indicators (KPIs) around sales, profit margins, and customer retention.

Core Objectives:
Data Hygiene: Clean, format, and structure raw sales data for robust analysis.

Sales Dynamics: Identify highest-grossing product categories and seasonal sales trends.

Customer Insights: Determine purchase frequency and segment high-value clients.

Stakeholder Reporting: Build an interactive, dynamic dashboard filterable by year, region, and product type.

🛠️ Tech Stack & Tools
Database & Querying: SQL (MySQL / PostgreSQL / SQL Server) — Data cleaning, EDA, Aggregations, Window Functions, CTEs.

Data Visualization: Tableau — Database connection, calculated fields, interactive dashboard design.

Data Source: Excel / CSV — Initial raw dataset format.

🗂️ Data Preparation & SQL Exploration
The raw dataset contained inconsistencies, null values, and formatting errors. SQL was leveraged to transform the data into a reliable source of truth.

Key SQL Techniques Demonstrated:
Database schema creation and constraint definitions.

Handling NULL values and removing duplicate records.

Relational modeling using JOIN statements across Customer and Sales tables.

Advanced analytics using CTEs and Window Functions (e.g., RANK(), PARTITION BY) to find top-selling items per region.

Date manipulation (EXTRACT, DATE_TRUNC) for time-series trend analysis.

📂 View the complete implementation in the sql_queries.sql file.

📈 Tableau Dashboard Features
The cleaned dataset was connected to Tableau to bring the metrics to life through an executive-ready interface:


