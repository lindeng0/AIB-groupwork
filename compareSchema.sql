DROP TABLE IF EXISTS sales;

CREATE TABLE sales(
    actual FLOAT NOT NULL,
    pred FLOAT NOT NULL,
    lineID INTEGER PRIMARY KEY,
    retailerName TEXT NOT NULL,
    -- retailerID INTEGER NOT NULL,
    invoiceDate DATE NOT NULL,
    invoiceDay TEXT NOT NULL,
    
    region TEXT NOT NULL,
    state TEXT NOT NULL,
    -- stateSales2020 INTEGER,
    -- stateSales2021 INTEGER,
    -- stateGDP2020 INTEGER ,
    -- stateGDP2021 INTEGER,
    -- statePopulation2020 INTEGER,
    -- statePopulation2021 INTEGER,
    city TEXT NOT NULL,

    product TEXT NOT NULL,
    gender TEXT,
    genderProduct TEXT,
    pricePerUnit REAL NOT NULL,
    unitsSold INTEGER NOT NULL,
    totalSales REAL NOT NULL,
    operatingProfit REAL NOT NULL,
    operatingMargin REAL NOT NULL,
    salesMethod TEXT NOT NULL
);

CREATE VIEW viewStateSales2020 AS
    SELECT state, sum(totalSales) as stateSales2020 FROM sales WHERE invoiceDate >= "2020-01-01" AND invoiceDate <= "2020-12-31" GROUP BY state
;

CREATE VIEW viewStateSales2021 AS
    SELECT state, sum(totalSales) as stateSales2021 FROM sales WHERE invoiceDate >= "2021-01-01" AND invoiceDate <= "2021-12-31" GROUP BY state
;