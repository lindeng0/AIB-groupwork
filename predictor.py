import os
import pandas as pd
import statsmodels.api as sm
from decimal import Decimal
import csv
import sqlite3


def importDataset(datasetCSV, cwd = str(os.getcwd())):
    CSVFile = cwd + '\\' + datasetCSV
    dataset = pd.read_csv(CSVFile)
    return dataset


def getPredictiveModel(y, xList, trainingDataCSV):
    trainingDataset = importDataset(trainingDataCSV)
    statement = '{0} ~ '.format(y)
    index = 0
    for x in xList:
        if index == 0:
            statement += '{0} '.format(x)
        else:
            statement += '+ {0} '.format(x)
        index += 1
    # print(statement)
    predictiveModel = sm.formula.ols(formula = statement, data = trainingDataset).fit()
    return predictiveModel


def updateCSV(variable, model, datasetCSV, outputCSV):
    
    dataset = importDataset(datasetCSV)
    with open(outputCSV, 'w', newline = '') as file:
        writer = csv.writer(file)
        title = ["actual_{0}".format(variable), "pred_{0}".format(variable), 'retailerName', 'invoiceDate', 'invoiceDay', 'region', 'state', 'stateSales2021', 'stateGDP2021', 'statePopulation2021', 'city', 'product', 'gender', 'genderProduct', 'pricePerUnit', 'unitsSold', 'totalSales', 'operatingProfit', 'operatingMargin', 'salesMethod']
        writer.writerow(title)
        
        predictions = model.predict(dataset)

        size = predictions.size
        for index, row in predictions.items():
            
            if (index + 1) % 100 == 0:
                print('[ {0:5d} / {1:5d} ]'.format((index + 1), size))
            
            actual                  = dataset.iloc[index][variable]                
            
            if variable == 'unitsSold':
                pred                = round(Decimal(row))
            else:
                pred                = round(Decimal(row), 2)
            
            retailerName            = dataset.iloc[index]['retailerName']
            invoiceDate             = dataset.iloc[index]['invoiceDate']
            invoiceDay              = dataset.iloc[index]['invoiceDay']
            region                  = dataset.iloc[index]['region']
            state                   = dataset.iloc[index]['state']
            stateSales2021          = dataset.iloc[index]['stateSales2021']
            stateGDP2021            = dataset.iloc[index]['stateGDP2021']
            statePopulation2021     = dataset.iloc[index]['statePopulation2021']
            city                    = dataset.iloc[index]['city']
            product                 = dataset.iloc[index]['product']
            gender                  = dataset.iloc[index]['gender']
            genderProduct           = dataset.iloc[index]['genderProduct']
            pricePerUnit            = dataset.iloc[index]['pricePerUnit']
            unitsSold               = dataset.iloc[index]['unitsSold']
            totalSales              = dataset.iloc[index]['totalSales']
            operatingProfit         = dataset.iloc[index]['operatingProfit']
            operatingMargin         = dataset.iloc[index]['operatingMargin']
            salesMethod             = dataset.iloc[index]['salesMethod']
            
            # print('actual: {0:4}; prediction: {1:4}'.format(actual, prediction))
            writer.writerow([actual, pred, retailerName, invoiceDate, invoiceDay, region, state, stateSales2021, stateGDP2021, statePopulation2021, city, product, gender, genderProduct, pricePerUnit, unitsSold, totalSales, operatingProfit, operatingMargin, salesMethod])

        print('[ {0:5d} / {1:5d} ]'.format(size, size))
        
   
predPricePerUnitModel = getPredictiveModel('pricePerUnit', ['retailerName', 'city', 'product', 'gender', 'salesMethod'], 'trainingData.csv')
# updateCSV('pricePerUnit', predPricePerUnitModel, 'dataset2021.csv', 'actualVSprediction2021(pricePerUnit).csv')


predUnitsSoldModel = getPredictiveModel('unitsSold', ['retailerName', 'state', 'product', 'pricePerUnit', 'salesMethod'], 'trainingData.csv')
# predUnitsSoldModel = getPredictiveModel('unitsSold', ['pricePerUnit'], 'trainingData.csv')
# updateCSV('unitsSold', predUnitsSoldModel, 'dataset2021.csv', 'actualVSprediction2021(unitsSold).csv')


predOperatingMarginModel = getPredictiveModel('operatingMargin', ['retailerName', 'state', 'salesMethod'], 'trainingData.csv')
# predOperatingMarginModel = getPredictiveModel('operatingMargin', ['pricePerUnit','retailerName', 'state', 'salesMethod'], 'trainingData.csv')
# predOperatingMarginModel = getPredictiveModel('operatingMargin', ['pricePerUnit'], 'trainingData.csv')
# updateCSV('operatingMargin', predOperatingMarginModel, 'dataset2021.csv', 'actualVSprediction2021(operatingMargin).csv')


def getOptimalPrice(retailerName, region, state, city, product, gender, salesMethod):

    for price in range(7, 111, 1):
        test = {'pricePerUnit': price, 'retailerName': retailerName, 'region': region, 'state': state, 'city': city, 'product': product, 'gender': gender, 'salesMethod': salesMethod}
        dataset = pd.DataFrame(data = test)
        
        index = 0
        
        predUnitsSold           = round(Decimal(predUnitsSoldModel.predict(dataset).iloc[0]))
        predOperatingMargin     = round(Decimal(predOperatingMarginModel.predict(dataset).iloc[0]), 4)
        
        predTotalSales          = predUnitsSold * price
        predOperatingProfit     = predTotalSales * predOperatingMargin
        
        print('price: {0:5d}; predUnitsSold: {1:4d}; predOperatingMargin: {2}; predTotalSales: {3:8.2f}; predOperatingProfit: {4:8.2f}'.format(price, predUnitsSold, str(round(predOperatingMargin * 100, 2)) + '%', predTotalSales, predOperatingProfit))
    print()


# salesMethod is going to be the filter. We will try to predict op. mrgin for outlet and in-store and online. We will compare them. 
# This will validate tables in slide 29 as well as the fact women's apparel is the one with biggest st.dev of op. margins  

def compareData(retailerName, region, state, city, product, gender, salesMethod):
    getOptimalPrice(retailerName, region, state, city, product, gender, salesMethod)

    conn = sqlite3.connect('test.db')
    parameters = [retailerName, region, state, city, product, gender, salesMethod]
    statement = 'SELECT DISTINCT avg(pricePerUnit) as pricePerUnit, avg(unitsSold) as unitsSold, avg(operatingMargin) as operatingMargin, avg(totalSales) as totalSales, avg(operatingProfit) as operatingProfit FROM sales WHERE retailerName = ? AND region = ? AND state = ? AND city = ? AND product = ? AND gender = ? AND salesMethod = ? GROUP BY retailerName, region, state, city, product, gender, salesMethod;'

    result = pd.read_sql_query(statement, conn, params = parameters)
    print(result)

    conn.close()
    
def writeDatabase(inputCSV, databaseName, variable):

    conn = sqlite3.connect(databaseName)
    c = conn.cursor()
    print('database ' + databaseName + ' connected')

    CSVFile = str(os.getcwd()) + '\\' + inputCSV
    with open(CSVFile, encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile)
        index = 1
        for row in reader:
            lineID = index
            actual = row["actual_{0}".format(variable)]
            pred = row["pred_{0}".format(variable)]
            retailerName = row['retailerName']
            invoiceDate = row['invoiceDate']
            invoiceDay = row['invoiceDay']
            region = row['region']
            state = row['state']
            city = row['city']
            product = row['product']
            gender = row['gender']
            genderProduct = row['genderProduct']
            pricePerUnit = row['pricePerUnit']
            unitsSold = row['unitsSold']
            totalSales = row['totalSales']
            operatingMargin = row['operatingMargin']
            operatingProfit = row['operatingProfit']      
            salesMethod = row['salesMethod']
    
    
            parameters = [lineID, actual, pred, retailerName, invoiceDate, invoiceDay, region, state, city, product, gender, genderProduct, pricePerUnit, unitsSold, totalSales, operatingProfit, operatingMargin, salesMethod]
            enquiry = "INSERT INTO sales (lineID, actual, pred, retailerName, invoiceDate, invoiceDay, region, state, city, product, gender, genderProduct, pricePerUnit, unitsSold, totalSales, operatingProfit, operatingMargin, salesMethod) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            c.execute(enquiry, parameters)
            
            conn.commit()
            if index % 100 == 0:
                print('[', index, ']')
            index += 1

    conn.close()
    print('[Writing Mode] finished')


def updateCSV(databaseName, outputCSV, preparedStatement, parameters = []):

    conn = sqlite3.connect(databaseName)
    print('database ' + databaseName + ' connected')
        
    csvOut = pd.read_sql_query(preparedStatement, conn, params = parameters)
    csvOut.to_csv(outputCSV, index = False)

    conn.close()
    print('[Updating Mode] finished')


# Ignacio's prediction of operating margin:
# updateCSV('operatingMargin', predOperatingMarginModel, 'dataset2021.csv', 'actualVSprediction2021(operatingMargin).csv')
# writeDatabase('actualVSprediction2021(operatingMargin).csv', 'compare.db', 'operatingMargin')
# preparedStatement = 'SELECT avg(pred), avg(actual), retailerName, region, product, gender, salesMethod FROM sales WHERE (retailerName = ? OR retailerName = ? OR retailerName = ?) AND (region = ? OR region = ?) AND gender = ? AND product = ? AND (salesMethod = ? OR salesMethod = ? OR salesMethod = ?) GROUP BY retailerName, region, product, gender, salesMethod ORDER BY retailerName, region, salesMethod;'
# parameters = ["Kohl's", "Sports Direct", "West Gear", "South", "West", "Female", "Apparel", "Online", "Outlet", "In-store"]
# updateCSV('compare.db', 'compare.csv', preparedStatement, parameters)
