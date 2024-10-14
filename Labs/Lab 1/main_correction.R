library(tidyverse)
library(purrr)
library(stringr)
library(readr)
library(lubridate)
library(janitor)
library(broom)

# Q1 Import ######################################################################
## Beginner way ##################
df_Calendar <- read_csv("AdventureWorks_Calendar.csv")
df_Customers <- read_csv("AdventureWorks_Customers.csv")
df_Product_Categories <- read_csv("AdventureWorks_Product_Categories.csv")
df_Product_Subcategories <- read_csv("AdventureWorks_Product_Subcategories.csv")
df_Products <- read_csv("AdventureWorks_Products.csv")
df_Returns <- read_csv("AdventureWorks_Returns.csv")
df_Sales_2015 <- read_csv("AdventureWorks_Sales_2015.csv")
df_Sales_2016 <- read_csv("AdventureWorks_Sales_2016.csv")
df_Sales_2017 <- read_csv("AdventureWorks_Sales_2017.csv")
df_Territories <- read_csv("AdventureWorks_Territories.csv")

## Advanced way ###################
# All the .csv are saved to a single object, df (it will be a "list of dataframes")
df <-
  # Map is a function that allows to repeat the same function over a list
  # https://purrr.tidyverse.org/reference/map.html
  map(
    # list.files() gives you all the files in the working directory, keep() keeps
    # strings in a list that satisfy some condition (here, all files that end with .csv)
    list.files() %>% keep(., ~ str_ends(.x, ".csv")),
    # ~ is an anonymous (or "lambda") functions: https://adv-r.hadley.nz/functionals.html?q=anonymous#purrr-shortcuts
    # Basically, ~ means that you create a function here that is not named, not saved in an object, and is only used once
    # Inputs are written: .x, .y...
    ~ read_csv(.x)
  ) %>%
  # This changes the names of the data.tables inside the object df
  # So they will be called "Calendar", "Customers", "Product_Categories", etc. etc.
  set_names(
    list.files() %>% keep(., ~ str_ends(.x, ".csv")) %>%
      str_remove_all("AdventureWorks_") %>%
      str_remove_all(".csv")
  )

# Data cleaning ################################################################
# Cleaning individual dataframes should be done first. Even if you wrote this code later during the exercice,
# move it early in your code.

# Modify calendar to get year, month, day, and day of the week
# Use lubridate functions
## Keep note the code formatting:
## - After a pipe, you should put a line break
## - Indent each time you call a function
## Here we have two levels of indentation: one after the mutate, one after the case_when
## This makes reading code easier; you can also do this automatically by clicking Code -> Reformat Code (shortcut: Ctrl Shift A)
df$Calendar <-
  df$Calendar %>%
  mutate(
    Date = as_date(Date, format = "%m/%d/%Y"),
    Year = year(Date),
    Month = month(Date),
    Day = day(Date),
    weekday = case_when(
      weekdays(Date) == "lundi" ~ "Monday",
      weekdays(Date) == "mardi" ~ "Tuesday",
      weekdays(Date) == "mercredi" ~ "Wednesday",
      weekdays(Date) == "jeudi" ~ "Thursday",
      weekdays(Date) == "vendredi" ~ "Friday",
      weekdays(Date) == "samedi" ~ "Saturday",
      weekdays(Date) == "dimanche" ~ "Sunday"
    )
  )

df$Customers <-
  df$Customers %>%
  mutate(
    AnnualIncome_num =
      AnnualIncome %>%
      str_remove_all("\\$") %>%
      str_remove_all(",") %>%
      as.numeric()
  )
df$Product_Categories
df$Product_Subcategories
df$Products
df$Returns
df$Sales_2015
df$Sales_2016
df$Sales_2017
df$Territories

# Question 2 #############################################
# Bind all sales tables into one
# Note: this creates a new dataframe inside the object df
df$Sales_all <-
  bind_rows(
    df$Sales_2015,
    df$Sales_2016,
    df$Sales_2017
  )

# How many orders in those three years?
nrow(df$Sales_all)
df$Sales_all %>%
  summarise(n = n())

# Question 3 #############################################
# Merge all products tables
df$Product_Subcategories
df$Product_Categories
df$Products

## Note that if you do this, the changes in the Products table won't be saved
df$Products %>%
  left_join(
    df$Product_Subcategories,
    by = "ProductSubcategoryKey"
  ) %>%
  left_join(
    df$Product_Categories,
    by = c("ProductCategoryKey" = "ProductCategoryKey") # Keys don't have to have the same name in both tables
  )
df$Products

# You need to "assign" the changes to an object
# We could assign that to df$Products, but here I decided to assign it to df$Products_all
df$Products_all <-
  df$Products %>%
  left_join(
    df$Product_Subcategories,
    by = "ProductSubcategoryKey"
  ) %>%
  left_join(
    df$Product_Categories,
    by = "ProductCategoryKey"
  )

# Question 4 ########################################################
# Merge all sales with products and customers and territory
df$sales_prod_cust <-
  df$Sales_all %>%
  left_join(
    df$Products_all,
    by = "ProductKey"
  ) %>%
  left_join(
    df$Customers,
    by = "CustomerKey"
  ) %>%
  left_join(
    df$Territories,
    by = c("TerritoryKey" = "SalesTerritoryKey")
  )
df$sales_prod_cust
df$sales_prod_cust %>% nrow()

# Question 5 ########################################################
# Merge all customers with the sales and territory tables, and then Products
# Is there a difference with the previous dataframe you built?
df$Customers %>%
  left_join(
    df$Sales_all %>%
      left_join(
        df$Territories,
        by = c("TerritoryKey" = "SalesTerritoryKey")
      ),
    by = "CustomerKey"
  ) %>%
  left_join(
    df$Products_all,
    by = "ProductKey"
  ) %>%
  nrow() # 56 778 rows, previously we had 56046
df$Customers %>%
  inner_join( # Here I used an inner join instead of a left_join
    df$Sales_all %>%
      left_join(
        df$Territories,
        by = c("TerritoryKey" = "SalesTerritoryKey")
      ),
    by = "CustomerKey"
  ) %>%
  left_join(
    df$Products_all,
    by = "ProductKey"
  ) %>%
  nrow()

# The difference comes from the fact that some customers never placed an order
# If you left join sales to customers, you keep customers that never ordered anything
# If you inner join sales to customers, you keep customers that are both in the customers and sales tables (i.e. customers that ordered something at least once)

# Question 6 ##################################################################
# How many people with income > $100,000?
# On which table should you do this?
df$Customers %>%
  filter(AnnualIncome_num > 100000)

# Question 7 ##################################################################
# Check if there are missing values in the Customer table
## Easy way
df$Customers %>%
  filter(
    is.na(CustomerKey) | is.na(Prefix) | is.na(FirstName) | is.na(LastName) |
    is.na(BirthDate) | is.na(MaritalStatus) | is.na(Gender) | is.na(EmailAddress) |
    is.na(AnnualIncome) | is.na(TotalChildren) | is.na(EducationLevel) | is.na(Occupation) |
    is.na(HomeOwner) | is.na(AnnualIncome_num)
  )
## Advanced way
df$Customers %>%
  filter(
    if_any(
      # if_any needs: a list of columns, a function
      .cols = everything(), # Here you put the columns on which you want to apply the function below
      .fn = ~ is.na(.x) # Here, a function that specifies the condition to keep observations
    )
  )
# What that does: keep rows that have missing values (this is specified in .fn)
# across any column in the data set (this is specified by the function everything())

# Question 8 ##################################################################
# How many orders have been made from people with income > $100000?
df$sales_prod_cust %>%
  filter(AnnualIncome_num > 100000) %>%
  View()
# 5676

# Question 9 ##################################################################
# Average price of product bought by people under and over $100K income?

# The easiest way (imo), is to create a new binary variable to distinguish
# people that earn >= 100000 from others
df$sales_prod_cust %>%
  mutate(
    over100k = case_when(AnnualIncome_num >= 100000 ~ "Yes", .default = "No"),
    total_order_price = OrderQuantity * ProductPrice # Note: one row can contain multiple bought items!
  ) %>%
  group_by(over100k) %>% # This allows to compute statistics over groups
  # So here, you will get the n, mean product price, and sd of product price
  # for each group in the variable "over100k)
  summarise(
    n = n(),
    avg_price = mean(total_order_price),
    sd_price = sd(total_order_price)
  ) %>%
  mutate(
    up_ci = avg_price + 1.96 * (sd_price/sqrt(n)),
    low_ci = avg_price - 1.96 * (sd_price/sqrt(n)),
  )

df_ttest <-
  df$sales_prod_cust %>%
  mutate(
    over100k = case_when(AnnualIncome_num >= 100000 ~ "Yes", .default = "No"),
    total_order_price = OrderQuantity * ProductPrice
  ) %>%
  select(total_order_price, over100k)

# The t.test function require two vectors of numerical data, but right now our data is in a table (df_ttest)
# Since we want to compare those that earn more than 100k to those that earn less
# We need to filter them in our df_ttest object, and then pull the order price column
t.test(
  x = df_ttest %>% filter(over100k == "Yes") %>% pull(total_order_price),
  y = df_ttest %>% filter(over100k == "No") %>% pull(total_order_price)
)


#Question 10 ##################################################################
# Distribution of prices of unique models of products ?
df$Products %>%
  distinct(ModelName, ProductPrice) %>%
  ggplot(
    aes(x = ProductPrice)
  ) +
  geom_histogram()

# Question 11 #################################################################
# Among customers, who bought the most expensive bike? Are there more high-earners who bought it, compared to lower-earners?
most_expensive_bike <-
  df$Products %>%
  filter(ProductPrice == max(ProductPrice)) %>%
  distinct(ModelName) %>%
  pull()
most_expensive_bike # I stored the name of the most expensive bike in an object

purchased_most_expensive_bike <-
  df$sales_prod_cust %>%
  # Note here: I call in the filter function the object I created just before, instead of writing "Road-150"
  # This way of doing things is nice if you want to automate your code: imagine you had a newer version of the database
  # with new products etc. etc., maybe the name of the most expensive product would have changed
  # With the way this is done here, the name of the most expensive product would be updated automatically
  filter(ModelName == most_expensive_bike) %>%
  distinct(CustomerKey)


df_most_expensive <-
  df$Customers %>%
  mutate(
    over100k = case_when(
      AnnualIncome_num >= 100000 ~ "Yes",
      .default = "No"),

    # What this does:
    # Look at every CustomerKey in the dataframe customers,
    # If it is contained in the dataframe we created in the previous step (those that bought the most expensive bike)
    # Then bought_most_expensive takes the value "Yes"
    bought_most_expensive = case_when(
      CustomerKey %in% purchased_most_expensive_bike$CustomerKey ~ "Yes",
      .default = "No"
    )
  ) %>%
  select(over100k, bought_most_expensive)

# How many bought the bike? In Prct?
df_most_expensive %>%
  count(bought_most_expensive) %>%
  mutate(prct = n/sum(n)*100)

# Were earners over 100k more likely to buy the most expensive bike?
# Do a twoway table with earnings status in column, bought the bike yes/no in row, and row percentages
# Export it to .csv
# Do a chi-squared test

# Rewrite and execute this code step by step if you want to properly understand it, there is a lot
# of data manipulation going that may be confusing at first
tw_table <-
  df_most_expensive %>%
  count(over100k, bought_most_expensive) %>%
  group_by(bought_most_expensive) %>%
  mutate(
    prct_row = n/sum(n) * 100
  ) %>%
  pivot_wider(
    names_from = over100k,
    values_from = c("n", "prct_row")
  ) %>%
  select(Variable = bought_most_expensive, `Earn < 100K` = prct_row_No, `Earn >= 100K` = prct_row_Yes) %>%
  mutate(Variable = case_when(
    Variable == "No" ~ "Did not buy the Road-150",
    Variable == "Yes" ~ "Bought the Road-150"
  ))
tw_table

tw_table %>% write_csv("test.csv") # This saves the table we just created to a csv file
table(df_most_expensive$over100k, df_most_expensive$bought_most_expensive) %>%
  chisq.test()


# Bonus ########################################################################
df_reg <-
  df$sales_prod_cust %>%
  mutate(
    total_profit = OrderQuantity * (ProductPrice - ProductCost)
  ) %>%
  group_by(CustomerKey) %>%
  summarise(Tot_profit = sum(total_profit)) %>%
  left_join(df$Customers) # Note: add customers with no purchases? Otherwise there is truncation here

df_reg %>%
  ggplot(
    aes(x = log(Tot_profit))
  ) +
  geom_histogram()

df_reg_res <-
  df_reg %>%
  lm(
    # Could add age, but I'm lazy
    log(Tot_profit) ~ MaritalStatus + Gender + as_factor(TotalChildren) + EducationLevel  + Occupation + HomeOwner + I(AnnualIncome_num / 10000),
    data = .
  )
tidy(df_reg_res, exponentiate = TRUE) # NB: interpretation is now multiplicative
glance(df_reg_res) # Not great.

# Ideally at this point you should look at residuals, notice that you violate the homoskedasticity assumption, etc.
# If you want to do a robust linear regression, look into the lmtest and sandwich packages
