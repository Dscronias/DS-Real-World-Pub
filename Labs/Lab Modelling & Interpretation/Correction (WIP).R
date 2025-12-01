# Setup ########################################################################
library(tidyverse)
library(janitor)
library(GGally)
library(gtsummary)
library(broom)
library(lmtest)
library(sandwich)
library(marginaleffects)
df <- read_rds("final_dataframe.v3.rds")

## Functions ###################################################################

# Find the number of patients that entered during the stay of some patient
# This just takes the input data, name of the service, date & hours of entry and exit
# Then just count the number of patients (you can subtract -1 to exclude the patient that you are calculating this indicator for)
n_patients <- function(data, p_service, h_entry, h_exit) {
  data %>% 
    filter(
      service == p_service & 
        entry >= h_entry & 
        exit <= h_exit
    ) %>% 
    summarise(n_patients = n()) %>% 
    pull(n_patients)
}

## New variables ################################################################

### Relative number of patient entries in the service ##########################
# When I build this variable, for any patient, I also include in the calculations 
# patients that entered 2 hours before
# The reason is that patients that entered before can have an impact on how your stay goes
# e.g. "overcrowding")
df <- 
  df %>% 
  mutate(
    entry_m2 = entry - hours(2) # This is entry minus 2 hours
  ) %>% 
  rowwise() %>% # This is a "group_by", where each row is a group
  # Not the most efficient because dplyr is bad at group computations
  # Data.table will be faster, especially on millions on rows. Here it is manageable. Just wait a few minutes
  mutate(
    number_patients = n_patients(df, service, entry_m2, exit)
  ) %>% 
  ungroup() %>% 
  group_by(service) %>% 
  mutate(
    time = difftime(max(exit), min(entry), units = "hours"),
    n_patients_service = n(),
    patients_per_hour = n_patients_service / as.numeric(time)
  ) %>% 
  ungroup() %>% 
  mutate(
    hours_spent = difftime(exit, entry_m2, units = "hours"),
    relative_n_entries = (number_patients/as.numeric(hours_spent))/patients_per_hour,
    los_8h = case_when(
      los >= 480 ~ "Yes",
      los < 480 ~ "No"
    ) %>% as_factor()
  )

### Other variable modifications ###############################################

df <- 
  df %>% 
  mutate(
    severity = as.numeric(severity),
    ald = case_when(ald == 0 ~ "No", .default = "Yes"),
    arrival_mode_sas = case_when(
      arrival_mode == "Personal" & sas == "Yes" ~ "Personal (SAS)",
      arrival_mode == "Personal" & sas == "No" ~ "Personal (not SAS)",
      .default = arrival_mode
    ),
    arrival_mode_sas = fct_relevel(arrival_mode_sas, "Personal (SAS)"),
    discharge_mode = fct_relevel(discharge_mode, "Home")
  )

# Exploratory ##################################################################

df %>% 
  tabyl(sas, arrival_mode)
## Note SAS is only defined for arrival_mode == Personal.
## Including SAS in any type of multivariable analysis would omit all the missing values
## One solution is to merge those two variables
df %>% 
  tabyl(arrival_mode_sas)

# Descriptive statistics #######################################################

## Univariate (by service)  ####################################################

## Checks
# Quite skewed
df %>% 
  ggplot(
    aes(x = cost)
  ) +
  geom_histogram()
# Better, but maybe not normal
df %>% 
  ggplot(
    aes(x = log(cost))
  ) +
  geom_histogram()

## Continuous variables
tbl_uni <- 
  df %>% 
  pivot_longer(
    cols = c(severity, los, age, cost, complexity, relative_n_entries),
    names_to = "Variable",
    values_to = "value"
  ) %>% 
  group_by(Variable, service) %>% 
  summarise(
    N = n(),
    `% missing` = round(sum(is.na(value)) / n() * 100, 2),
    Min = min(value, na.rm = TRUE),
    P10 = quantile(value, 0.1, na.rm = TRUE),
    P25 = quantile(value, 0.25, na.rm = TRUE),
    P50 = quantile(value, 0.5, na.rm = TRUE),
    P75 = quantile(value, 0.75, na.rm = TRUE),
    P90 = quantile(value, 0.9, na.rm = TRUE),
    Max = max(value, na.rm = TRUE)
  )
print(tbl_uni, n = 100)

### Export
# Use write_excel_csv (write_excel_csv2 if you are French) if you need to open it in Excel
tbl_uni %>% 
  write_excel_csv2("tbluni.csv")
tbl_uni %>% 
  mutate(
    across(
      c("Min", "P10", "P25", "P50", "P75", "P90", "Max"),
      ~ round(.x, 2)
    )
  ) %>% 
  as_gtsummary()

## Categorical variables
map(
  c("discharge_mode", "arrival_mode_sas", "ald", "los_8h"),
  ~ df %>% 
    tabyl(!!sym(.x), service_code) %>% 
    adorn_totals("col") %>% 
    adorn_percentages("col") %>% 
    adorn_pct_formatting()
) # Note : 10% of helicopter arrivals and only 39% personal arrivals is very weird?
df %>% 
  tbl_summary(
    include = c("discharge_mode", "arrival_mode", "ald", "los_8h"),
    by = service_code,
    statistic = list(
      all_categorical() ~ "{p}%"
    )
  ) %>% 
  add_p()

## Bivariate ###################################################################
### Categorical ################################################################
map(
  c("discharge_mode", "arrival_mode_sas", "ald"),
  ~ df %>% 
    tabyl(!!sym(.x), los_8h) %>% 
    adorn_totals("row") %>% 
    adorn_percentages("row") %>% 
    adorn_pct_formatting()
)

### Cat * cont #################################################################
cont_bivariate_table <- function(.data, .var_col) {
  .data %>% 
    pivot_longer(
      cols = c(discharge_mode, arrival_mode_sas, ald),
      names_to = "Variable",
      values_to = "value"
    ) %>% 
    group_by(Variable, value) %>% 
    summarise(
      N = n(),
      `Mean` = mean({{.var_col}}, na.rm = TRUE),
      `Min` = min({{.var_col}}, na.rm = TRUE),
      `P10` = quantile({{.var_col}}, 0.1, na.rm = TRUE),
      `P25` = quantile({{.var_col}}, 0.25, na.rm = TRUE),
      `P50` = quantile({{.var_col}}, 0.5, na.rm = TRUE),
      `P75` = quantile({{.var_col}}, 0.75, na.rm = TRUE),
      `P90` = quantile({{.var_col}}, 0.9, na.rm = TRUE),
      `Max` = max({{.var_col}}, na.rm = TRUE)
    )
}
df %>% 
  cont_bivariate_table(los)
df %>% 
  cont_bivariate_table(cost)

### Cont #######################################################################
ggpair_fit <-
  function(data, mapping) {
    ggplot(data = data, mapping = mapping) +
      geom_point(alpha = 0.05) +
      geom_smooth(method = "glm", formula = y ~ x, fill = "blue", color = "red", linewidth = 0.5, method.args = list(family = poisson))
  }
ggpairs(
  df %>% 
    select(severity, age, cost, relative_n_entries, los),
  upper = list(continuous = wrap(ggally_cor, method = "spearman")),
  lower = list(continuous = wrap(ggpair_fit))
)

# Multivariable ################################################################

## Setup #######################################################################

df_reg <- 
  df %>% 
  as.data.frame()

## LOS 8h ######################################################################
res_logit <- 
  glm(
    los_8h ~ service_code + discharge_mode + arrival_mode_sas + age + complexity + ald + relative_n_entries,
    family = "binomial",
    data = df_reg
  )
tidy(res_logit, exponentiate = TRUE) # Raw results are log-odds. This gives you odds ratios.
lrtest(res_logit) # Tells you if your fitted model is better than a model with just a constant

### Risk ratios ################################################################

#### Robust poisson method
res_poisson <- 
  df_reg %>% 
  mutate(los_8h = case_when(los_8h == "No" ~ 0, los_8h == "Yes" ~ 1)) %>% 
  glm(
    los_8h ~ service_code + discharge_mode + arrival_mode_sas + age + complexity + ald + relative_n_entries,
    family = "poisson",
    data = .
  )
coeftest(res_poisson, vcov. = vcovHC) %>% 
  tidy(conf.int = TRUE) %>% 
  mutate(
    across(
      c(estimate, conf.low, conf.high),
      ~ exp(.x)
    )
  ) %>% 
  select(term, estimate, conf.low, conf.high, p.value)

#### With marginal effects
avg_comparisons(res_logit, comparison = "lnratioavg", transform = exp)

## Costs #######################################################################
res_costs <- 
  glm(
    cost ~ service_code + discharge_mode + arrival_mode_sas + age + complexity + ald + relative_n_entries + los,
    family = gaussian(link = "log"), # Alternative to explicitly modelling log(cost), which would require a specific correction when taking exp(coefficients)
    data = df
  )
tidy(res_costs, exponentiate = TRUE)
tbl_res_cost <-
  coeftest(res_costs, vcov. = vcovHC) %>% 
  tidy(conf.int = TRUE) %>% 
  mutate(
    across(
      c(estimate, conf.low, conf.high),
      ~ exp(.x)
    )
  )

res_costs_alt <- 
  glm(
    cost ~ service_code + discharge_mode + arrival_mode_sas + age + complexity + ald + relative_n_entries,
    family = gaussian(link = "log"),
    data = df
  )
tbl_res_cost_alt <-
  coeftest(res_costs_alt, vcov. = vcovHC) %>% 
  tidy(conf.int = TRUE) %>% 
  mutate(
    across(
      c(estimate, conf.low, conf.high),
      ~ exp(.x)
    )
  )

tbl_res_cost %>% 
  select(term, estimate_m1 = estimate) %>% 
  left_join(
    tbl_res_cost_alt %>% 
      select(term, estimate_m2 = estimate)
  ) %>% View()
