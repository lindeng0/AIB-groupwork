dataset2020 <- dataset[dataset$invoiceDate > '2019-12-31' & dataset$invoiceDate < '2021-01-01',]
dataset2021 <- dataset[dataset$invoiceDate > '2020-12-31' & dataset$invoiceDate < '2022-01-01',]


totalSalesSum <- sum(dataset$totalSales)
totalSalesSum2020 <- sum(dataset2020$totalSales)
totalSalesSum2021 <- sum(dataset2021$totalSales)

unitsSoldSum <- sum(dataset$unitsSold)
unitsSoldSum2020 <- sum(dataset2020$unitsSold)
unitsSoldSum2021 <- sum(dataset2021$unitsSold)

pricePerUnitMean <- mean(dataset$pricePerUnit)
pricePerUnitMean2020 <- mean(dataset2020$pricePerUnit)
pricePerUnitMean2021 <- mean(dataset2021$pricePerUnit)

pricePerUnitSD <- sd(dataset$pricePerUnit)
pricePerUnitSD2020 <- sd(dataset2020$pricePerUnit)
pricePerUnitSD2021 <- sd(dataset2021$pricePerUnit)

operatingProfitSum <- sum(dataset$operatingProfit)
operatingProfitSum2020 <- sum(dataset2020$operatingProfit)
operatingProfitSum2021 <- sum(dataset2021$operatingProfit)

operatingMarginMean <- mean(dataset$operatingMargin)
operatingMarginMean2020 <- mean(dataset2020$operatingMargin)
operatingMarginMean2021 <- mean(dataset2021$operatingMargin)

operatingMarginSD <- sd(dataset$operatingMargin)
operatingMarginSD2020 <- sd(dataset2020$operatingMargin)
operatingMarginSD2021 <- sd(dataset2021$operatingMargin)

install.packages("psych")
install.packages("corx")
library(psych)
library(corx)
options(scipen = 100000)

desc_tab <- psych::describe(dataset)
desc_tab2020 <- psych::describe(dataset2020)
desc_tab2021 <- psych::describe(dataset2020)

desc_tab

write.csv(desc_tab, file ="descriptives_table.csv")
write.csv(desc_tab2020, file ="descriptives_table2020.csv")
write.csv(desc_tab2021, file ="descriptives_table2021.csv")