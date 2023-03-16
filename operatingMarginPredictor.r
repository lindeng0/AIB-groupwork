# import dataset and filter by year
library(readxl)
library(psych)
library(dplyr)
library(Metrics)
library(ggplot2)

# -----------------------------------------------------------------------------------------------------------
# dataset <- read.csv("C:/Users/a1lin/Desktop/dataset.csv", stringsAsFactors = TRUE)
# dataset2021 <- dataset[dataset$invoiceDate > '2020-12-31' & dataset$invoiceDate < '2022-01-01',]
dataset2021 <- read.csv("C:/Users/a1lin/Desktop/test/dataset2021.csv", stringsAsFactors = TRUE)

# summary dataset
summary(dataset2021)
summary(dataset2021$operatingProfit)
hist(dataset2021$operatingProfit)

hist(dataset2021$operatingMargin)

# pairs.panels(dataset2021[c("retailerName","region", "state", "stateSales2021","stateGDP2021", "statePopulation2021","product", "gender", "pricePerUnit", "unitsSold", "totalSales", "operatingProfit", "operatingMargin", "salesMethod")])

# pairs.panels(dataset2021[c("retailerName", "product", "gender","pricePerUnit","unitsSold", "totalSales", "operatingProfit", "operatingMargin")])

pairs.panels(dataset2021[c("pricePerUnit","unitsSold", "totalSales", "operatingProfit", "operatingMargin")])

# -----------------------------------------------------------------------------------------------------------
# multiple regression

# correlation matrix
# all rows, and columns 17(pricePerUnit), 18(unitsSold), 19(totalSales), 20(operatingProfit), 21(operatingMargin)
features <- dataset2021[, c(17,18,19,20,21)]
correlation <- cor(features) # larger number indicates a stronger correlation of pairs
round(correlation, 2)

#                 pricePerUnit unitsSold totalSales operatingProfit operatingMargin
# pricePerUnit            1.00      0.22       0.51            0.46           -0.12
# unitsSold               0.22      1.00       0.91            0.88           -0.21
# totalSales              0.51      0.91       1.00            0.95           -0.21
# operatingProfit         0.46      0.88       0.95            1.00            0.01
# operatingMargin        -0.12     -0.21      -0.21            0.01            1.00

# need to be cautious about: multicollinearity / interaction
# normally, the higher the R-squared, the better the model fits your data,
# but extremely high R-squared may signals multicollinearity / interaction
# e.g.,
lm_multicollinearity <- lm(unitsSold ~ totalSales + pricePerUnit, data = dataset2021)
summary(lm_multicollinearity)
# adjusted R-squared = 91.27
# => not going to include total sales and operating profits when building a predictive model as variables


# all variables
lm_operatingMargin_0 <- lm(operatingMargin ~ retailerName + invoiceDay + region + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)

# test: retailer
lm_operatingMargin_1 <- lm(operatingMargin ~ invoiceDay + region + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_operatingMargin_0, lm_operatingMargin_1)
# => keep retailer

# test invoiceDay
lm_operatingMargin_2 <- lm(operatingMargin ~ retailerName + region + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_operatingMargin_0, lm_operatingMargin_2)
# => exlucde invoiceDay

# test: region
lm_operatingMargin_3 <- lm(operatingMargin ~ retailerName + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_operatingMargin_2, lm_operatingMargin_3)
# => exclude region

# test: state
lm_operatingMargin_4 <- lm(operatingMargin ~ retailerName + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_operatingMargin_3, lm_operatingMargin_4)
# => keep state

# test: city
lm_operatingMargin_5 <- lm(operatingMargin ~ retailerName + state + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_operatingMargin_3, lm_operatingMargin_5)
# => exclude city

# test: product
lm_operatingMargin_6 <- lm(operatingMargin ~ retailerName + state + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_operatingMargin_5, lm_operatingMargin_6)
# => exclude product

# test: gender
lm_operatingMargin_7 <- lm(operatingMargin ~ retailerName + state + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_operatingMargin_6, lm_operatingMargin_7)
# => exclude gender

# test pricePerUnit
lm_operatingMargin_8 <- lm(operatingMargin ~ retailerName + state + salesMethod, data = dataset2021)
anova(lm_operatingMargin_7, lm_operatingMargin_8)
# => exclude pricePerUnit

# test salesMethod
lm_operatingMargin_9 <- lm(operatingMargin ~ retailerName + state, data = dataset2021)
anova(lm_operatingMargin_8, lm_operatingMargin_9)
# => retain salesMethod

summary(lm_operatingMargin_9)

# Model : adjusted R-squared:
#     0 : 47.39%
#     1 : 47.21%
#     2 : 47.40%
#     3 : 47.40%
#     4 : 46.29%
#     5 : 47.03%
#     6 : 46.71%
#     7 : 46.60%
#     8 : 46.61%
#     9 : 21.17%

# final linear model:
# lm_operatingMargin_8 <- lm(operatingMargin ~ retailerName + state + salesMethod, data = dataset2021)

# to see how operatingMargin change, variables includes:
# retailerName, state, salesMethod

# -----------------------------------------------------------------------------------------------------------

# Step 1: Create the training and test data samples from original data

# setting seed to reproduce results of random sampling
set.seed(100)


# row indices for training data
# 80% to train the model, 20% to test the model
# select 80% of the row indexes (6869个行号中选其中5495个) => print(sample(1:6869, 5495))
trainingRowIndex <- sample(1:nrow(dataset2021), 0.8*nrow(dataset2021))

# training dataset
trainingData <- dataset2021[trainingRowIndex,]
dim(trainingData)
# write.csv(trainingData, "C:\\Users\\a1lin\\Desktop\\test\\trainingData.csv", row.names = FALSE)

# test dataset
testData <- dataset2021[-trainingRowIndex,]
dim(testData)
# write.csv(testData, "C:\\Users\\a1lin\\Desktop\\test\\testData.csv", row.names = FALSE)

# -----------------------------------------------------------------------------------------------------------
# step 2.1: build the model on training data
pred_unitsSold <- lm(unitsSold ~ retailerName + state + product + pricePerUnit + salesMethod, data = trainingData)
summary(pred_unitsSold) # pay attention into the adjusted R-squared: 54.97%

pred_operatingMargin <- lm(operatingMargin ~ retailerName + state + salesMethod, data = dataset2021)
summary(pred_operatingMargin)


# -----------------------------------------------------------------------------------------------------------

# best (RMSE = 0.06811641)
pred_operatingMargin <- lm(operatingMargin ~ retailerName + state + salesMethod, data = trainingData)

# all variables (RMSE = 0.06703396)
pred_operatingMargin <- lm(operatingMargin ~ retailerName + invoiceDay + region + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)

# drop retailer (RMSE = 0.06824103)
pred_operatingMargin <- lm(operatingMargin ~ state + salesMethod, data = trainingData)

# add invoiceDay (RMSE = 0.06813466)
pred_operatingMargin <- lm(operatingMargin ~ invoiceDay + retailerName + state + salesMethod, data = trainingData)

# add region (RMSE = 0.06811641)
pred_operatingMargin <- lm(operatingMargin ~ region + retailerName + state + salesMethod, data = trainingData)

# drop state (RMSE = 0.08146912)
pred_operatingMargin <- lm(operatingMargin ~ retailerName + salesMethod, data = trainingData)

# add city (RMSE = 0.06742395)
pred_operatingMargin <- lm(operatingMargin ~ retailerName + state + product + gender + pricePerUnit + salesMethod, data = dataset2021)

# add product (RMSE = 0.06773889)
pred_operatingMargin <- lm(operatingMargin ~ product + retailerName + state + salesMethod, data = trainingData)

# add gender (RMSE = 0.06743202)
pred_operatingMargin <- lm(operatingMargin ~ gender + retailerName + state + pricePerUnit + salesMethod, data = dataset2021)

# add pricePerUnit (RMSE = 0.06756353)
pred_operatingMargin <- lm(operatingMargin ~ pricePerUnit + retailerName + state + salesMethod, data = dataset2021)

# add salesMethod (RMSE = 0.06756596)
pred_operatingMargin <- lm(operatingMargin ~ salesMethod + retailerName + state, data = dataset2021)

# -----------------------------------------------------------------------------------------------------------

# predict the price for all the records in test data
operatingMargin_predict <- predict(pred_operatingMargin, newdata = testData)

actualsOperatingMargin_VS_predictedOperatingMargin <- data.frame(cbind(actual = testData$operatingMargin, predicted = operatingMargin_predict))
head(actualsOperatingMargin_VS_predictedOperatingMargin)

# step 3: evaluate the model; calculate RMSE

rmse(actualsOperatingMargin_VS_predictedOperatingMargin$actual, actualsOperatingMargin_VS_predictedOperatingMargin$predicted) # 0.06811641

# -----------------------------------------------------------------------------------------------------------

pred_operatingMargin <- lm(operatingMargin ~ retailerName + state + salesMethod, data = trainingData)

ggplot(dataset2021, aes(pricePerUnit, operatingMargin)) + 
  geom_smooth()

ggplot(dataset2021, aes(pricePerUnit, unitsSold)) + 
  geom_smooth()

pred_operatingMargin
# Coefficients:
#               (Intercept)    retailerNameFoot Locker         retailerNameKohl's  retailerNameSports Direct  
#                   0.49530                   -0.02583                   -0.01031                   -0.02047  
#       retailerNameWalmart      retailerNameWest Gear                stateAlaska               stateArizona  
#                  -0.03055                   -0.01908                   -0.22757                   -0.18828  
#             stateArkansas            stateCalifornia           stateConnecticut              stateDelaware  
#                  -0.13605                   -0.16915                   -0.13106                   -0.10969  
#              stateFlorida               stateGeorgia                stateHawaii                 stateIdaho  
#                  -0.16196                   -0.17190                   -0.23535                   -0.12142  
#             stateIllinois               stateIndiana                  stateIowa                stateKansas  
#                  -0.10431                   -0.10035                   -0.10900                   -0.22543  
#             stateKentucky             stateLouisiana                 stateMaine              stateMaryland  
#                  -0.19656                   -0.11456                   -0.18315                   -0.12603  
#        stateMassachusetts              stateMichigan           stateMississippi              stateMissouri  
#                  -0.19117                   -0.05498                   -0.11956                   -0.07954  
#              stateMontana              stateNebraska         stateNew Hampshire            stateNew Jersey  
#                  -0.10947                   -0.09620                   -0.16205                   -0.11623  
#           stateNew Mexico              stateNew York        stateNorth Carolina          stateNorth Dakota  
#                  -0.19430                   -0.11232                   -0.17009                   -0.14304  
#                 stateOhio              stateOklahoma                stateOregon          statePennsylvania  
#                  -0.19121                   -0.15361                   -0.12069                   -0.11295  
#         stateRhode Island        stateSouth Carolina          stateSouth Dakota             stateTennessee  
#                  -0.11640                   -0.19983                   -0.22973                   -0.04292  
#                stateTexas                  stateUtah               stateVermont              stateVirginia  
#                  -0.08943                   -0.08586                   -0.10903                   -0.11134  
#        stateWest Virginia             stateWisconsin               stateWyoming          salesMethodOnline  
#                  -0.07945                   -0.11408                   -0.14138                    0.12071  
#         salesMethodOutlet  
#                   0.05004

# actual_prediction_operatingMarin_2021 analysis
actual_prediction_operatingMargin_2021 <- read.csv("C:/Users/a1lin/Desktop/test/actualVSprediction2021(operatingMargin).csv", stringsAsFactors = TRUE)

rmse(actual_prediction_operatingMargin_2021$actual_operatingMargin, actual_prediction_operatingMargin_2021$pred_operatingMargin) # RMSE = 0.0667776

pairs.panels(actual_prediction_operatingMargin_2021[c('actual_operatingMargin', 'pred_operatingMargin')])

ggplot(actual_prediction_operatingMargin_2021, aes(actual_operatingMargin, pred_operatingMargin)) + 
  geom_smooth()
