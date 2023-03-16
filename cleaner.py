# Notice: need to re-save the original Adidas US Sales.csv into a utf-8 format csv file.
import os
from datetime import datetime
import sqlite3
from time import sleep
import pandas as pd
from decimal import Decimal
import csv

def getNumber(number):
    cleanNumber = number.replace(',','').replace('$','')
    if cleanNumber[-1] == '%':
        cleanNumber = float(cleanNumber.replace('%',''))/100
    return float(cleanNumber)


def writeDatabase(inputCSV, databaseName, writingMode, printMode):
    if writingMode:
        conn = sqlite3.connect(databaseName)
        c = conn.cursor()
        print('database ' + databaseName + ' connected')

    CSVFile = str(os.getcwd()) + '\\' + inputCSV
    with open(CSVFile, encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile)
        lineID = 2 # exclude the title of attributes
        
        for row in reader:
            
            if printMode:
                print('lineID: ' + str(lineID))
            
            retailerName = row['Retailer']
            if printMode:
                print('retailerName: ' + retailerName)
            
            # retailerID = row['Retailer ID']
            # if printMode:
            #     print('retailerID: ' + retailerID)
            
            invoiceDate = row['Invoice Date'].replace("/","-")
            invoiceDate = datetime.strptime(invoiceDate, '%Y-%m-%d').date()
            if printMode:
                print('invoiceDate: ' + str(invoiceDate))
            
            invoiceDay = invoiceDate.weekday()
            if invoiceDay == 0:
                invoiceDay = 'Monday'
            if invoiceDay == 1:
                invoiceDay = 'Tuesday'
            if invoiceDay == 2:
                invoiceDay = 'Wednesday'
            if invoiceDay == 3:
                invoiceDay = 'Thursday'
            if invoiceDay == 4:
                invoiceDay = 'Frirday'
            if invoiceDay == 5:
                invoiceDay = 'Saturday'
            if invoiceDay == 6:
                invoiceDay = 'Sunday'
            if printMode:
                print('invoiceDay: ' + str(invoiceDay))
            
            region = row['Region']
            if printMode:
                print('region: ' + region)
            
            state = row['State']
            if printMode:
                print('state: ' + state)
            
            city = row['City']
            if printMode:
                print('city: ' + city)
            
            genderProduct = row['Product']
            gender = 'Null' 
            if("Men's " in genderProduct):
                gender = 'Male'
                product = genderProduct.replace("Men's ","")
            elif("Women's " in genderProduct):
                gender = 'Female'
                product = genderProduct.replace("Women's ", "")
            
            if printMode:
                print('product: ' + product)
            
            if printMode:
                print('gender: ' + gender)
            
            if printMode:
                print('GenderProduct: ' + genderProduct)
            
            pricePerUnit = getNumber(row['Price per Unit'])
            if printMode:
                print('pricePerUnit: ' + str(pricePerUnit))
            
            unitsSold = int(getNumber(row['Units Sold']))
            if printMode:
                print('unitsSold: ' + str(unitsSold))
            
            # totalSales = getNumber(row['Total Sales'])
            totalSales = pricePerUnit * unitsSold
            if printMode:
                print('totalSales: ' + str(totalSales))
            
            # operatingProfit = getNumber(row['Operating Profit'])
            # if printMode:
            #     print('operatingProfit: ' + str(operatingProfit))
            
            operatingMargin = getNumber(row['Operating Margin'])
            if printMode:
                print('operatingMargin: ' + str(operatingMargin))

            operatingProfit = float(round(Decimal(totalSales * operatingMargin), 2))
            if printMode:
                print('operatingProfit: ' + str(operatingProfit))
            
            # if (pricePerUnit * unitsSold) != (totalSales):
            #     raise Exception('(pricePerUnit * unitsSold) != (totalSales)')
            
            
            # print(totalSales * operatingMargin)
            # print(round(operatingProfit,0))
            # if (totalSales * operatingMargin) != round(operatingProfit,0):
            #     raise Exception('totalSales * operatingMargin != operatingProfit')
            # else:
            #     print('[2] pass')
            
            salesMethod = row['Sales Method']
            if printMode:
                print('salesMethod: ' + salesMethod)
            
            if printMode:
                print()
        
            if writingMode:
                parameters = [lineID, retailerName, invoiceDate, invoiceDay, region, state, city, product, gender, genderProduct, pricePerUnit, unitsSold, totalSales, operatingProfit, operatingMargin, salesMethod]
                enquiry = "INSERT INTO sales (lineID, retailerName, invoiceDate, invoiceDay, region, state, city, product, gender, genderProduct, pricePerUnit, unitsSold, totalSales, operatingProfit, operatingMargin, salesMethod) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                c.execute(enquiry, parameters)
                conn.commit()
                print(lineID)
            
            lineID += 1
    if writingMode:
        conn.close()
        print('[Writing Mode] finished')
    
    
def removeRepetition(databaseName):
    conn = sqlite3.connect(databaseName)
    c = conn.cursor()
    print('database ' + databaseName + ' connected')
    
    # repetitionStatement = 'SELECT a.lineID, b.lineID, a.retailerName, a.invoiceDate, a.region, a.state, a.city, a.product, a.gender, a.salesMethod, a.pricePerUnit, b.pricePerUnit, a.unitsSold, b.unitsSold, a.operatingMargin, b.operatingMargin FROM sales a JOIN sales b USING (retailerName, invoiceDate, region, state, city, product, gender, salesMethod) WHERE a.lineID <> b.lineID;'
    # 3372 lines (of 9648 lines); 9648 - 3372 = 6276
    getRepetitiousLineStatement = 'SELECT a.lineID AS aLineID, b.lineID AS bLineID, retailerName, invoiceDate, region, state, city, product, gender, salesMethod FROM sales a JOIN sales b USING (retailerName, invoiceDate, region, state, city, product, gender, salesMethod) WHERE a.lineID <> b.lineID AND a.lineID < b.lineID;'
    repetitiousLine = pd.read_sql_query(getRepetitiousLineStatement, conn)
    print('There are', len(repetitiousLine.index) * 2, 'repetitious line(s).')
    
    
    for index, row in repetitiousLine.iterrows():
        retailerName = row['retailerName']
        invoiceDate = row['invoiceDate']
        region = row['region']
        state = row['state']
        city = row['city']
        product = row['product']
        gender = row['gender']
        salesMethod = row['salesMethod']
        
        aLineID = row['aLineID']
        bLineID = row['bLineID']
        getASalesInfoStatement = 'SELECT lineID, pricePerUnit, unitsSold, operatingMargin, totalSales FROM sales WHERE lineID = ?;'
        getBSalesInfoStatement = 'SELECT lineID, pricePerUnit, unitsSold, operatingMargin, totalSales FROM sales WHERE lineID = ?;'
        
        ASalesInfoStatement = pd.read_sql_query(getASalesInfoStatement, conn, params = [str(aLineID)])
        BSalesInfoStatement = pd.read_sql_query(getBSalesInfoStatement, conn, params = [str(bLineID)])
        
        AUnitsSold = int(ASalesInfoStatement.iloc[0]['unitsSold'])
        BUnitsSold = int(BSalesInfoStatement.iloc[0]['unitsSold'])
        sumUnitsSold = AUnitsSold + BUnitsSold
        
        APricePerUnit = round(Decimal(ASalesInfoStatement.iloc[0]['pricePerUnit']), 2)
        BPricePerUnit = round(Decimal(BSalesInfoStatement.iloc[0]['pricePerUnit']), 2)
        weightPricePerUnit = ((APricePerUnit * AUnitsSold) + (BPricePerUnit * BUnitsSold)) / sumUnitsSold
        roundWeightPricePerUnit = round(Decimal(weightPricePerUnit), 2)
        
        AOperatingMargin = round(Decimal(ASalesInfoStatement.iloc[0]['operatingMargin']), 4)
        BOperatingMargin = round(Decimal(BSalesInfoStatement.iloc[0]['operatingMargin']), 4)
        weightOperatingMargin = ((AOperatingMargin * AUnitsSold) + (BOperatingMargin * BUnitsSold)) / sumUnitsSold
        roundweightOperatingMargin = round(Decimal(weightOperatingMargin), 4)
        
        ATotalSales = round(Decimal(ASalesInfoStatement.iloc[0]['totalSales']), 2)
        BTotalSales = round(Decimal(BSalesInfoStatement.iloc[0]['totalSales']), 2)
        
        sumTotalSales = sumUnitsSold * roundWeightPricePerUnit
        # sumTotalSales = ATotalSales + BTotalSales
        sumOperatingProfit = sumTotalSales * roundweightOperatingMargin

        # print('[A] lineID: {0:4}, pricePerUnit: {1:2f}, unitSold: {2:4d}, operatingMargin: {3:4f}, totalSales: {4:10f}'.format(aLineID, APricePerUnit, AUnitsSold, AOperatingMargin, ATotalSales))
        # print('[B] lineID: {0:4}, pricePerUnit: {1:2f}, unitSold: {2:4d}, operatingMargin: {3:4f}, totalSales: {4:10f}'.format(bLineID, BPricePerUnit, BUnitsSold, BOperatingMargin, BTotalSales))
        # print('[S]               pricePerUnit: {0:2f}, unitSold: {1:4d}, operatingMargin: {2:4f}, totalSales: {3:10f}, A and B sales: {4: 10f}'.format(roundWeightPricePerUnit, sumUnitsSold, roundweightOperatingMargin, sumTotalSales, ATotalSales + BTotalSales))
        # print()
        # sleep(3)
        
        deleteStatement = 'DELETE FROM sales WHERE lineID = ?;'
        c.execute(deleteStatement, [bLineID])
        conn.commit()
        updateStatement = 'UPDATE sales SET pricePerUnit = ?, unitsSold = ?, totalSales = ?, operatingProfit = ?, operatingMargin = ? WHERE lineID = ?;'
        parameters = [float(roundWeightPricePerUnit), sumUnitsSold, float(sumTotalSales), float(sumOperatingProfit), float(roundweightOperatingMargin), aLineID]
        c.execute(updateStatement, parameters)
        conn.commit()
        
    conn.close()


def appendState(databaseName, printMode):
    conn = sqlite3.connect(databaseName)
    c = conn.cursor()
    print('database ' + databaseName + ' connected')
    stateCSVLocation = str(os.getcwd()) + '\\state.csv'
    with open(stateCSVLocation, encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile)
        lineID = 1
        for row in reader:
            
            if printMode:
                print('lineID: ' + str(lineID))
                
            state = row['state']
            if printMode:
                print('state: ' + state)
            
            stateGDP2020 = row['stateGDP2020']
            if printMode:
                print('stateGDP2020: ' + stateGDP2020)
            
            stateGDP2021 = row['stateGDP2021']
            if printMode:
                print('stateGDP2021: ' + stateGDP2021)
            
            statePopulation2020 = row['statePopulation2020']
            if printMode:
                print('statePopulation2020: ' + statePopulation2020)
            
            statePopulation2021 = row['statePopulation2021']
            if printMode:
                print('statePopulation2021: ' + statePopulation2021)
            
            parameters = [stateGDP2020, stateGDP2021, statePopulation2020, statePopulation2021, state]
            enquiry = "UPDATE sales SET stateGDP2020 = ?, stateGDP2021 = ?, statePopulation2020 = ?, statePopulation2021 = ? WHERE state = ?"
            c.execute(enquiry, parameters)
            conn.commit()
            lineID += 1
            
    updateStateSales2020Statement = 'UPDATE sales SET stateSales2020 = (SELECT stateSales2020 FROM viewStateSales2020 WHERE state = sales.state)'
    updateStateSales2021Statement = 'UPDATE sales SET stateSales2021 = (SELECT stateSales2021 FROM viewStateSales2021 WHERE state = sales.state)'
    c.execute(updateStateSales2020Statement)
    c.execute(updateStateSales2021Statement)
    conn.commit()
    conn.close()
    print('[state append] finished')
    
    
def updateCSV(preparedStatement, databaseName, outputCSV):

    conn = sqlite3.connect(databaseName)
    print('database ' + databaseName + ' connected')
        
    csvOut = pd.read_sql_query(preparedStatement, conn)
    csvOut.to_csv(outputCSV, index = False)

    conn.close()
    print('[Updating Mode] finished')




# CSVlocation = str(os.getcwd()) + '\\' + CSVname
# oldCSVlocation = str(os.getcwd()) + '\\' + oldCSVname

# writeDatabase('sample.csv', 'test.db', 1, 0)
# removeRepetition('test.db')
# appendState('test.db', 0)

dataset = 'SELECT * FROM sales ORDER by invoiceDate, state, retailerName, city, product, gender, salesMethod'
# updateCSV(dataset, 'test.db', 'dataset.csv')

dataset2021 = 'SELECT * FROM sales WHERE invoiceDate > "2020/12/31" AND invoiceDate < "2022/01/01" ORDER by invoiceDate, state, retailerName, city, product, gender, salesMethod'
# updateCSV(dataset2021, 'test.db', 'dataset2021.csv')

dataset2021_OM_over_30 = 'SELECT * FROM sales WHERE operatingMargin >= 0.3 AND invoiceDate > "2020/12/31" AND invoiceDate < "2022/01/01" ORDER by invoiceDate, state, retailerName, city, product, gender, salesMethod'
# updateCSV(dataset2021_OM_over_30, 'test.db', 'dataset2021(OM over 30).csv')




# writeDatabase('adidas.csv', 'old.db', 1, 0)
# appendState('old.db', 0)


