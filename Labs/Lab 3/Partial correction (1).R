library(shiny)
library(bslib)
library(tidyverse)
library(DT)
library(plotly)
library(bsicons)
library(broom)
library(marginaleffects)
library(DALEX)

# Functions
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

# Data exercise ################################################################

# Setup
df_es <-
  read_rds("final_dataframe.v3.rds")
df_es <-
  df_es %>% 
  mutate(
    entry_m2 = entry - hours(2) # This is entry minus 2 hours
  ) %>% 
  rowwise() %>%
  mutate(
    number_patients = n_patients(df_es, service, entry_m2, exit)
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
    los_8h =
      case_when(
        los >= 480 ~ "Yes",
        los < 480 ~ "No"
      ) %>%
      as_factor(),
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

# Logistic regression
res_logit <- 
  glm(
    los_8h ~ service_code + discharge_mode + arrival_mode_sas + age + complexity + ald,
    family = "binomial",
    data = df_es
  )

# Odds ratios
res_logit_or <- tidy(res_logit, exponentiate = TRUE, conf.int = TRUE)

# Risk ratios
res_logit_rr <- avg_comparisons(res_logit, comparison = "lnratioavg", transform = exp)

# Exports
write_rds(df_es, "df_modified.rds")
write_rds(res_logit_or, "res_logit_or.rds")
write_rds(res_logit_rr, "res_logit_rr.rds")
