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

pairs.panels(dataset2021[c("retailerName","region", "state", "stateSales2021","stateGDP2021", "statePopulation2021","product", "gender", "pricePerUnit", "unitsSold", "totalSales", "operatingProfit", "operatingMargin", "salesMethod")])

pairs.panels(dataset2021[c("retailerName", "product", "gender","pricePerUnit","unitsSold", "totalSales", "operatingProfit", "operatingMargin")])

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
lm_unitsSold_0 <- lm(unitsSold ~ retailerName + invoiceDay + region + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)

# test: retailer
lm_unitsSold_1 <- lm(unitsSold ~ invoiceDay + region + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_unitsSold_0, lm_unitsSold_1) 
# p-value = 0.00008669 < 0.05

# The F-statistic is a measure of the difference in variance explained by the two 
# models. The p-value measures the statistical significance of the F-statistic. In this
# case, the p-value is less than 0.001, which indicates strong evidence that the two
# models are significantly different.

# Specifically, Model 2 has a higher RSS (more residual variation) than Model 1,
# indicating that it explains less of the variation in the response variable. The F-statistic 
# of 5.22 indicates that the difference in variance explained by the two models is
# significant. The very small p-value of 8.669e-05 indicates that there is strong 
# evidence to reject the null hypothesis that the two models are equivalent.

# Overall, this ANOVA test suggests that including "retailerName" in the model results 
# in a significant improvement in the ability to explain the variation in "unitsSold".

# => retain reatiler

# test invoiceDay
lm_unitsSold_2 <- lm(unitsSold ~ retailerName + region + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_unitsSold_0, lm_unitsSold_2)
# p-value = 0.154 > 0.05

# In this case, the p-value is 0.154, which is greater than the typical threshold of 0.05 used to
# determine statistical significance. This indicates that there is not strong evidence to 
# reject the null hypothesis that the two models are equivalent.

# Specifically, Model 2 has a higher RSS (more residual variation) than Model 1,
# indicating that it explains less of the variation in the response variable. However, the 
# small difference in RSS (Sum of Sq) and the non-significant F-statistic suggest that 
# dropping "invoiceDay" from the model does not result in a significant decrease in its
# explanatory power.

# => Overall, this ANOVA test suggests that dropping "invoiceDay" from the model does
# not significantly impact the ability to explain the variation in "unitsSold".

# => exclude invoiceDay 

# test: region
lm_unitsSold_3 <- lm(unitsSold ~ retailerName + state + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_unitsSold_2, lm_unitsSold_3)
# => exclude region

# test: state
lm_unitsSold_4 <- lm(unitsSold ~ retailerName + city + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_unitsSold_3, lm_unitsSold_4)
# => keep state

# test: city
lm_unitsSold_5 <- lm(unitsSold ~ retailerName + state + product + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_unitsSold_3, lm_unitsSold_5)
# => drop city

# test: product
lm_unitsSold_6 <- lm(unitsSold ~ retailerName + state + gender + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_unitsSold_5, lm_unitsSold_6)
# => retain product

# test: gender
lm_unitsSold_7 <- lm(unitsSold ~ retailerName + state + product + pricePerUnit + salesMethod, data = dataset2021)
anova(lm_unitsSold_5, lm_unitsSold_7)
# => exclude gender

# test pricePerUnit
lm_unitsSold_8 <- lm(unitsSold ~ retailerName + state + product + salesMethod, data = dataset2021)
anova(lm_unitsSold_7, lm_unitsSold_8)
# => retain pricePerUnit

lm_unitsSold_9 <- lm(unitsSold ~ retailerName + state + product + pricePerUnit, data = dataset2021)
anova(lm_unitsSold_7, lm_unitsSold_9)
# => retain pricePerUnit

summary(lm_unitsSold_9)

# Model : adjusted R-squared:
#     0 : 56.02%
#     1 : 55.88%
#     2 : 56.00%
#     3 : 56.00%
#     4 : 48.83%
#     5 : 55.98%
#     6 : 51.16%
#     7 : 55.50%
#     8 : 48.60%
#     9 : 44.52%

# final linear model:
# lm_unitsSold_7 <- lm(unitsSold ~ retailerName + state + product + pricePerUnit + salesMethod, data = dataset2021)

# to see how unitsSold change, variables includes:
# retailerName, state, product, pricePerUnit, salesMethod

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
write.csv(trainingData, "C:\\Users\\a1lin\\Desktop\\test\\trainingData.csv", row.names = FALSE)

# test dataset
testData <- dataset2021[-trainingRowIndex,]
dim(testData)
write.csv(testData, "C:\\Users\\a1lin\\Desktop\\test\\testData.csv", row.names = FALSE)

# -----------------------------------------------------------------------------------------------------------
# step 2.1: build the model on training data
pred_unitsSold <- lm(unitsSold ~ retailerName + state + product + pricePerUnit + salesMethod, data = trainingData)
summary(pred_unitsSold) # pay attention into the adjusted R-squared: 54.97%

# -----------------------------------------------------------------------------------------------------------
# attempt to change variables

# best (RMSE = 176.5339)
pred_unitsSold <- lm(unitsSold ~ retailerName + state + product + pricePerUnit + salesMethod, data = trainingData)

# all variables (RMES = 175.621)
pred_unitsSold <- lm(unitsSold ~ retailerName + invoiceDay + region + state + city + product + gender + pricePerUnit + salesMethod, data = trainingData)

# drop retailerName (RMSE = 176.6922)
pred_unitsSold <- lm(unitsSold ~ state + product + pricePerUnit + salesMethod, data = trainingData)

# drop state (RMSE = 244.59)
pred_unitsSold <- lm(unitsSold ~ retailerName + product + pricePerUnit + salesMethod, data = trainingData)

# drop product (RMSE = 187.6617)
pred_unitsSold <- lm(unitsSold ~ retailerName + state + pricePerUnit + salesMethod, data = trainingData)

# drop pricePerUnit (RMSE = 192.4783)
pred_unitsSold <- lm(unitsSold ~ retailerName + state + product + salesMethod, data = trainingData)

# drop salesMethod (RMSE = 198.4859)
pred_unitsSold <- lm(unitsSold ~ retailerName + state + product + pricePerUnit, data = trainingData)

# add invoiceDay (RMSE = 176.4155)
pred_unitsSold <- lm(unitsSold ~ invoiceDay + retailerName + state + product + pricePerUnit + salesMethod, data = trainingData)

# add gender (RMSE = 175.6711)
pred_unitsSold <- lm(unitsSold ~ gender + retailerName + state + product + pricePerUnit + salesMethod, data = trainingData)

# -----------------------------------------------------------------------------------------------------------
# step 2.2: use the pred_unitsSold trained to predict units sold in test data

# predict the price for all the records in test data
unitsSold_predict <- predict(pred_unitsSold, newdata = testData)

actualsUnitsSold_VS_predictedUnitsSold <- data.frame(cbind(actual = testData$unitsSold, predicted = unitsSold_predict))
head(actualsUnitsSold_VS_predictedUnitsSold)

# step 3: evaluate the model; calculate RMSE

rmse(actualsUnitsSold_VS_predictedUnitsSold$actual, actualsUnitsSold_VS_predictedUnitsSold$predicted) # 176.5339


# -----------------------------------------------------------------------------------------------------------

test <- lm(unitsSold ~ pricePerUnit, data = trainingData)
summary(test)

test <- lm(operatingMargin ~ pricePerUnit, data = trainingData)
summary(test)

pred_unitsSold <- lm(unitsSold ~ retailerName + state + product + pricePerUnit + salesMethod, data = trainingData)

ggplot(dataset2021, aes(pricePerUnit, unitsSold)) + 
  geom_smooth()

ggplot(dataset2021, aes(pricePerUnit, operatingMargin)) + 
  geom_smooth()

pred_unitsSold
"
Coefficients:
             (Intercept)    retailerNameFoot Locker         retailerNameKohl's  retailerNameSports Direct  
                 271.441                     32.440                     65.218                     59.420  
     retailerNameWalmart      retailerNameWest Gear                stateAlaska               stateArizona  
                  20.394                     46.956                   -284.935                   -124.765  
           stateArkansas            stateCalifornia           stateConnecticut              stateDelaware  
                 -15.869                     55.167                   -365.569                   -335.634  
            stateFlorida               stateGeorgia                stateHawaii                 stateIdaho  
                -295.993                    -51.539                   -296.147                     25.393  
           stateIllinois               stateIndiana                  stateIowa                stateKansas  
                -289.725                   -311.878                   -313.024                     25.282  
           stateKentucky             stateLouisiana                 stateMaine              stateMaryland  
                  18.169                   -173.539                   -277.979                   -382.836  
      stateMassachusetts              stateMichigan           stateMississippi              stateMissouri  
                -370.899                   -182.665                      7.162                   -190.041  
            stateMontana              stateNebraska         stateNew Hampshire            stateNew Jersey  
                -181.410                   -267.957                   -273.560                   -370.095  
         stateNew Mexico              stateNew York        stateNorth Carolina          stateNorth Dakota  
                -150.205                   -176.420                    452.551                   -327.578  
               stateOhio              stateOklahoma                stateOregon          statePennsylvania  
                 290.960                   -102.089                   -344.599                   -318.088  
       stateRhode Island        stateSouth Carolina          stateSouth Dakota             stateTennessee  
                -362.855                    568.686                    -81.542                     18.431  
              stateTexas                  stateUtah               stateVermont              stateVirginia  
                  29.361                   -191.156                   -330.418                   -320.380  
      stateWest Virginia             stateWisconsin               stateWyoming   productAthletic Footwear  
                -304.241                   -318.643                   -189.977                     54.450  
  productStreet Footwear               pricePerUnit          salesMethodOnline          salesMethodOutlet  
                 142.506                      6.091                   -242.936                   -146.490  
"

# actual_prediction_unitsSold_2021 analysis
actual_prediction_unitsSold_2021 <- read.csv("C:/Users/a1lin/Desktop/test/actualVSprediction2021(unitsSold).csv", stringsAsFactors = TRUE)

rmse(actual_prediction_unitsSold_2021$actual_unitsSold, actual_prediction_unitsSold_2021$pred_unitsSold) # RMSE = 173.9258

pairs.panels(actual_prediction_unitsSold_2021[c('actual_unitsSold', 'pred_unitsSold')])

ggplot(actual_prediction_unitsSold_2021, aes(actual_unitsSold, pred_unitsSold)) + 
  geom_smooth()

