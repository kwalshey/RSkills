library(data.table)
library(ggplot2)
library(fst)
library(lubridate)
library(RQuantLib)

################################# Question 1. ###################################
# Chart the aggregate Enterprise Value to aggregate Sales and                   #
# median Enterprise Value to Sales relative to the World for all                #
# US listed stocks on the same chart.                                           #
# Please exclude any sectors where this valuation metric doesn’t make sense.    #
#################################################################################


# read in data using fst, then convert to data.table
monthly_world_val <- setDT(read.fst("ext_data/monthly_world_val.fst"))

# investigate unique country levels to ensure US isn't referenced multiple times
# under various guises
levels(monthly_world_val[,COUNTRY])
country <- "United States"

monthly_US_val <- monthly_world_val[COUNTRY==country]

# investigate sectors for validity
levels(monthly_US_val[,SECTOR])

# we will ignore the EXCLUDE sector for this analysis, all other sectors appear fine

exclude <- "EXCLUDE"
monthly_US_val_ex <- monthly_US_val[SECTOR!=exclude]

# calculate aggregate and median EV/Sales through time
monthly_US_val_ex_grp <- monthly_US_val_ex[, .(EV_agg = sum(EV), SALES_agg = sum(SALES),
                             EV_med = median(EV), SALES_med = median(SALES)), by=.(DATE)]
EV_to_SALES <- monthly_US_val_ex_grp[, .(DATE, EVSALES_agg = EV_agg/SALES_agg,
                                         EVSALES_med = EV_med/SALES_med)]

# reshape data for ease of graphical combination
EV_to_SALES_melt <- melt(EV_to_SALES, id.vars=c("DATE"),
                         measure.vars=c("EVSALES_agg", "EVSALES_med"),
                         value.name="EVSALES",
                         variable.name="DataSeries")

# graph data
ggplot(data=EV_to_SALES_melt, aes(x=DATE, y=EVSALES, color=DataSeries)) + geom_line()


################################# Question 2. ###################################
# Create a daily total return price index for the largest 500 stocks (at each   #
# point in time) listed on the US market                                        #
#################################################################################

##################################### a.#########################################
# present a chart of this time series                                           #
#################################################################################


# read in data using fst, then convert to data.table
daily_prices <- setDT(read.fst("ext_data/daily_US_prices.fst"))

# investigate unique country levels to ensure US isn't referenced multiple times
# under various guises
levels(daily_prices[,COUNTRY])
country <- "United States"

daily_US_prices <- daily_prices[COUNTRY==country]
# appears data was already correctly filtered

# as data is split, spinoff and dividend adjusted, we don't need to manually adjust
# our data series' for this

# choose our index divisor
divisor <- 35000

# using an order and index method here - faster than using head()
daily_US_prices_500 <- daily_US_prices[order(DATE, -MARKET_CAP)][, .SD[1:500], by=DATE]
US_TR_index <- daily_US_prices_500[, PRICE_CAP:=PRICE*MARKET_CAP
                                   ][,.(INDEX=sum(PRICE_CAP)/divisor), by=DATE]

ggplot(data=US_TR_index, aes(x=DATE, y=INDEX)) + geom_line()

################################### b. ##########################################
# Calculate the 3Y rolling return of your index and plot againt the 3Y          #
# rolling return of the S&P500 on the same chart                                #
#################################################################################

# determine start date for rolling return calcs
start_date <- US_TR_index[,min(DATE)]
start_roll <- start_date %m+% years(3)

# calculate returns using 3y lagged data as intermediate step
# using lagged data is quicker than a roll function here
horizon <- US_TR_index[DATE==start_roll, which=TRUE]
US_TR_lag <- US_TR_index[,LAG:=shift(INDEX, horizon-1, type = "lag")]
US_TR_ret <- na.omit(US_TR_lag[, .(DATE, INDEX=INDEX/LAG-1)]) # non-annualised

ggplot(data=US_TR_ret, aes(x=DATE, y=INDEX)) + geom_line()

################################### c. ##########################################
# Present a table with the following summary statistics of your index           #
# Start Date, Start Index Value, End Date, End Index Value,                     #
# Cumulative Total Return, Cumulative Total Return p.a.,                        #
# Volatility of Daily Returns (annualised)                                      #
#################################################################################


# daily returns
data_count <- nrow(US_TR_index)
US_TR_ret_daily <- na.omit(US_TR_index[,LAG:=shift(INDEX, 1, type = "lag")][,RET:=INDEX/LAG-1])

# calculate output values for tables
table_start_date <- US_TR_index[,min(DATE)]
table_start_value <- US_TR_index[DATE==table_start_date, INDEX]
table_end_date <- US_TR_index[,max(DATE)]
table_end_value <- US_TR_index[DATE==table_end_date, INDEX]
table_total_return <- table_end_value/table_start_value - 1

# total period for annualisation
time_period <- as.numeric((table_end_date - table_start_date)/365.25)
table_total_return_pa <- (1+table_total_return)^(1/time_period)-1

#assume 260 trading days
table_vol_pa <- sd(US_TR_ret_daily[,RET])*sqrt(260)


################################# Question 3. ###################################
# Chart the 30d average annualised standard deviation of daily returns for all  #
# US stocks in the top quintile of market capitalisation (at each point in time)#
#################################################################################

# Here we sort date data on date and descending market cap
# Then determine the amount of stocks at each date to calculate a top quintile
# Filter by the floor of this top quintile number
# Carry out in one step via chaining to minimise handling large data

daily_US_prices_topquint <- daily_US_prices[order(DATE, -MARKET_CAP)
                                            ][,COUNT:=.N, by=DATE
                                              ][, .SD[1:floor(COUNT[1]/5)], by=DATE
                                                ][,COUNT:=NULL]

# calculate daily returns by lagging price columns per ticker group
# then, calculate a rolling standard deviation over a 30day window
# again, chaining to reduce data handling
daily_US_ret_topquint <- daily_US_prices_topquint[
  ,LAG:=shift(PRICE, 1, type = "lag"), by=TICKER
  ][,RET:=PRICE/LAG-1
    ][, STDEV:=frollapply(RET,30,sd), by=TICKER]

# remove leading data for sd calc
daily_US_ret_topquint <- na.omit(daily_US_ret_topquint, cols="STDEV")

# calculate annualised average across all stocks for each date
daily_US_sd_avg <- daily_US_ret_topquint[,.(STDEV_avg=mean(STDEV)*sqrt(260)), by=DATE]

ggplot(data=daily_US_sd_avg, aes(x=DATE, y=STDEV_avg)) + geom_line()


################################# Question 4. #####################################
# If 5% of your portfolio was invested in Microsoft, how could you completely     #
# hedge out the risk of downward price movements in the most capital efficient way#
###################################################################################

msft <- daily_US_prices[TICKER=="MSFT-US"]

# to hedge out of downward price movement:
# 1. short underlying stock
# 2. purchase ATM put options
# 3. fully delta hedge at each point in time using MSFT single stock futures
#     (SSFs aren't traded in the US)
#
# Shorting the stock will require a large amount of initial and variation margin,
# whereas buying puts just has the initial premium outlay

initial_portfolio <- 100000

# Shorting Capital Requirement

msft_exposure <- initial_portfolio * 0.05
margin_acc <- 1.5

total_margin <- margin_acc * msft_exposure

# Put Option Capital Requirement

# Assumptions

div <- 0.02
rfr <- 0.0175
t <- 1
vol <- daily_US_ret_topquint[TICKER=="MSFT-US",.SD[.N], by=TICKER][,STDEV]*sqrt(260)

option_price <- EuropeanOption("put", msft_exposure, msft_exposure, div, rfr, t, vol)$value

# we can also hedge out the movements from MSFT by performing regressions between it and other stocks
# to keep this problem less data intensive, we'll just look in the same sector as MSFT,
# as this is where we're likely to see the highest correlations

# edit hyphens from tickers to underscores for easier parsing

daily_sftw_prices <- daily_US_prices[SECTOR=="Software"]
daily_sftw_prices[
  ,LAG:=shift(PRICE, 1, type = "lag"), by=TICKER
  ][,RET:=PRICE/LAG-1][
    , TICKER2:=sub("-", "_", TICKER)]

# remove equities with no prices as at most recent date - naturally we can't hedge using these
max_dates <- daily_sftw_prices[,.(LAST_DATE=max(DATE)), by=TICKER2]
discontinued_stocks <- max_dates[LAST_DATE<"2018-07-19", TICKER2]

# reshape to carry out linear regression
daily_sftw_reshape <- dcast(daily_sftw_prices, DATE~TICKER2, value.var=c("RET"))

# remove stocks with N/A at present date
daily_sftw_reshape[,(discontinued_stocks):=NULL]
sftw_stocks <- colnames(daily_sftw_reshape)[-1]

# perform a univariate regression against all remaining stocks
pvalues <- daily_sftw_reshape[,sapply(.SD, function(x) {summary(lm(MSFT_US ~ x - 1))$coefficients[,4]}), .SDcols=sftw_stocks]
coefs <- daily_sftw_reshape[,sapply(.SD, function(x) {coef(lm(MSFT_US ~ x - 1))}), .SDcols=sftw_stocks]

# find smallest beta for which p-value is still <0.001
best_hedge <- coefs[which(coefs==min(coefs[pvalues<0.001]))]
capital <- best_hedge * msft_exposure * margin_acc

# with a significant beta of only 0.034, we would only need to short 0.17% of our portfolio to hedge MSFT
# this is less than the option premium, even when accounting for a margin of potentially 1.5 times

