# RSkills
Solution to RSkills test

## Directory Structure

* R - Contains .R scripts providing solutions to the test
* ext_data - Contains external data sources (these are not uploaded to the repo - in reality large files like this would be saved at another remote location)
* outputs - Contains output from scripts as specifically requested in the test

## Overview

The code has been written in a scripting style as this is the most efficient way to provide the requested answers.
If this code was to be ported to an application the structure would need to employ stronger package structuring using devtools. I've included a barebones structure so that this could be easily converted to a package, but haven't initially created the code with that in mind.

Regardless of it's usage, all code benefits from version control, and so I've created this GitHub repo.

## Question Analysis
### Question 1
I've saved a ggplot graph of various EV/SALES metrics in the outputs/ folder under Question1.png

### Question 2 (a)
I've saved a graph of the constructed total return index in the outputs/ folder under Question2a.png

### Question 2 (b)
I've saved a graph of the 2 constructed returns series' in the outputs/ folder under Question2b.png

### Question 2 (c)
Here is the requested table filled out:
Start Date | Start Index Value | End Date | End Index Value | Cumulative Total Return | Cumulative Total Return p.a. | Volatility of Daily Returns (annualised)
----------------- | ----------------- | ----------------- | ----------------- | ----------------- | ----------------- | -----------------
1994-12-30 | 31.87 | 2018-07-19 | 286.71 | 799.52% | 9.78% | 21.98%

### Question 3
I've saved a graph of the standard deviations in the outputs/ folder under Question3.png

### Question 4
To hedge out of downward price movement we can:
1. Short the underlying stock
1. Purchase ATM put options
1. Fully delta hedge at each point in time using MSFT single stock futures
    1. (SSFs aren't traded in the US - so this isn't a realistic option)

Shorting the stock will require a large amount of initial and variation margin, whereas buying puts just has the initial premium outlay

Within the script, I've shown that the margin requirement to short a stock is greater than the option price for a given set of reasonable assumptions
