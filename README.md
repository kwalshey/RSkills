# RSkills
Solution to RSkills test

## Directory Structure

* R - Contains .R scripts providing solutions to the test
* ext_data - Contains external data sources 
    * Large files are not uploaded to the repo - in reality files like this would be saved at another remote location
    * Please add `daily_US_prices.fst` and `monthly_world_val.fst` to this folder in order to run the R code
    * `SP500.csv` is included here - no need to add this
* outputs - Contains output from scripts as specifically requested in the test

## Overview

The code has been written in a scripting style as this is the most efficient way to provide the requested answers.
If this code was to be ported to an application the structure would need to employ stronger package structuring using devtools. I've included a barebones structure so that this could be easily converted to a package, but haven't initially created the code with that in mind.

Regardless of it's usage, all code benefits from version control, and so I've created this GitHub repo.

## Question Analysis
### Question 1
I've saved a ggplot graph of various EV/SALES metrics in the `outputs/` folder under `Question1.png`

### Question 2 (a)
I've saved a graph of the constructed total return index in the `outputs/` folder under `Question2a.png`

### Question 2 (b)
I've saved a graph of the 2 constructed returns series' in the `outputs/` folder under `Question2b.png`

### Question 2 (c)
Here is the requested table filled out:
Start Date | Start Index Value | End Date | End Index Value | Cumulative Total Return | Cumulative Total Return p.a. | Volatility of Daily Returns (annualised)
----------------- | ----------------- | ----------------- | ----------------- | ----------------- | ----------------- | -----------------
1994-12-30 | 459.27 | 2018-07-19 | 3183.02 | 593.06% | 8.56% | 17.24%

### Question 3
I've saved a graph of the standard deviations in the `outputs/` folder under `Question3.png`

### Question 4
To hedge out of downward price movement we can:
1. Short the underlying stock
2. Short stocks with similar characteristics
3. Purchase ATM put options
4. Fully delta hedge at each point in time using MSFT single stock futures
    1. (SSFs aren't traded in the US - so this isn't a realistic option)

Shorting the stock will require a large amount of initial and variation margin, whereas buying puts just has the initial premium outlay

I additionally wanted to investigate shorting stocks with similar characteristics to MSFT in order to hedge them. I hadn't carried out analysis like this before, so this methodology was new to me. I looked at a univariate regression of MSFT against other stocks in the software sector. Disregarding the regressions that weren't significant, I took the lowest slope value against Microsoft, reasoning that this would require the smallest hedge amount. I feel this methodology may have quite a large amount of basis risk, and the put option may be a more robust approach over the required time period.

Within the script, I've shown that the margin requirement to short a stock is greater than the option price for a given set of reasonable assumptions, and that shorting a the similar stock is less capital intensive again.
