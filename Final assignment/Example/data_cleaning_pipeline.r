# Setup ########################################################################
library(tidyverse)
library(glue)
library(janitor)
library(nnet)
library(kknn)

set.seed(999)

# Importing ####################################################################
df_n_patients <- read_csv("number_of_patients.csv")
df_complexity <- read_csv("complexity_codes.csv")

## Batch dataset import ########################################################
df <- list(
  Batushka = 
    read_csv("data_su1.csv", skip = 2),
  
  `Denzel Curry` = 
    read_csv("data_su_denzel_curry.csv") %>% 
    mutate(
      service = "Denzel Curry"
    ) %>% 
    rename(discharge_mode = exit_method),
  
  Luther = 
    read_rds("data_su3.rds") %>% 
    mutate(dob_year = as.numeric(dob_year)),
  
  `La Fève` = 
    read_csv("data_su4.csv"),
  
  winnterzuko = 
    read_csv2("data_su5.csv") %>% 
    distinct(id, .keep_all = TRUE) %>% 
    rename(discharge_mode = arrival_mode, arrival_mode = discharge_mode) %>% 
    mutate(age = floor(age)),
  
  Changeline = 
    read_csv("data_su6.csv") %>% 
    select(-xxz2, -starts_with("ccm"), -starts_with("."), -cmp12),
  
  `Crystal Castles` = 
    read_csv("data_su8.csv") %>% 
    mutate(
      dob = glue("{dob_year}/{dob_month}/{dob_day}"),
      adm_entry = glue("{administrative_entry_date} {administrative_entry_hour}")
    ) %>% 
    group_by(dob, adm_entry) %>% 
    mutate(
      n = n()
    ) %>% 
    filter(
      n == 1 |
        n > 1 & !is.na(diagnostic)
    ) %>% 
    ungroup() %>% 
    select(-n, -dob, -adm_entry, -ok),
  
  abel31 = 
    read_csv2("data_su9.csv")
)

## Individual modifications ####################################################
df_age <- 
  df$abel31 %>% 
  select(id, starts_with("age")) %>% 
  pivot_longer(
    cols = -id,
    names_to = "age",
    values_to = "values"
  ) %>% 
  filter(!is.na(values)) %>% 
  mutate(age = age %>% str_remove("age_") %>% as.numeric()) %>% 
  select(-values)

df$abel31 <- 
  df$abel31 %>% 
  select(-starts_with("age")) %>% 
  left_join(df_age)

df <- 
  df %>% 
  map(
    ~ .x %>% mutate(
      across(
        c("severity", "discharge_mode", "entry_date", "discharge_date",
          "administrative_entry_date", "entry_hour", "discharge_hour",
          "administrative_entry_hour"),
        as.character
      )
    )
  )

## Concatenation ###############################################################
df_full <- 
  df %>% 
  bind_rows()

# Variable creation ############################################################
df_full <- 
  df_full %>% 
  mutate(
    entry = paste(entry_date, entry_hour, sep = " ") %>% 
      parse_date_time(orders = "%Y-%m-%d %H:%M:%S"),
    exit = paste(discharge_date, discharge_hour, sep = " ") %>% 
      parse_date_time(orders = "%Y-%m-%d %H:%M:%S"),
    entry_year = year(entry),
    age = case_when(
      is.na(age) ~ entry_year - dob_year,
      .default = age
    ),
    los = difftime(exit, entry, units = "mins") %>% as.numeric(),
    diagnostic = str_remove(diagnostic, "\\."),
    service_type = case_when(
      service %in% c("Batushka", "Changeline", "Luther") ~ "Adult",
      .default = "Adult + Pediatric"
    ),
    severity = case_when(
      severity == "1 C Seule" ~ "1",
      severity == "P" ~ NA_character_, # Psychiatric patients, rare, won't bother.
      severity == "na" ~ NA_character_,
      .default = severity
    ),
    discharge_mode = case_when(
      discharge_mode %in% c("9", "D", "Died", "Death") ~ "Died",
      discharge_mode %in% c("8", "E", "External", "Home", "Went home") ~ "Home",
      discharge_mode %in% c("6", "H", "H2", "Hosp", "Hospit", "Hospitalised") ~ "Hospitalised",
      discharge_mode %in% c("7", "Other hospital", "T", "Transfer", "Transfered", "Transfered to other hospital") ~ "Transfered to other hospital",
      is.na(discharge_mode) | discharge_mode %in% c("na") ~ NA_character_,
    ),
    arrival_mode = case_when(
      arrival_mode == "SMUR" ~ "Ambulance + life support",
      arrival_mode == "VSAB" ~ "Ambulance + firefighters",
      arrival_mode == "na" ~ NA_character_,
      .default = arrival_mode
    ),
    los = case_when(
      los < 0 ~ NA_real_,
      los > 4320 ~ NA_real_, # Stays over 72h are *very* rare, possibly a problem
      .default = los
    )
  ) %>% 
  select(-c(entry_date, entry_hour, discharge_date, discharge_hour, entry_year)) %>% 
  left_join(df_complexity)

# Filtering ####################################################################
df_to_filter <- 
  df_full %>% 
  group_by(service) %>% 
  summarise(
    n = n(),
    across(
      c("discharge_mode", "arrival_mode", "los", "age", "complexity"),
      ~ (sum(is.na(.x), na.rm = TRUE) / n()) * 100,
      .names = "{.col}_na"
    )
  ) %>% 
  filter(
    if_any(
      contains("na"),
      ~ .x > 30
    )
  )

df_full_filtered <- 
  df_full %>% 
  filter(
    !service %in% (df_to_filter %>% pull(service))
  )

# Imputation ###################################################################
df_full_filtered <- 
  df_full_filtered %>% 
  # LOS median imputation by service
  group_by(service) %>% 
  mutate(
    los = case_when(
      is.na(los) ~ median(los, na.rm = TRUE),
      .default = los
    )
  ) %>% 
  ungroup() %>% 
  # Discharge mode, mode imputation
  mutate(
    discharge_mode = case_when(
      is.na(discharge_mode) ~ "Home",
      .default = discharge_mode
    )
  )
    
## Arrival mode imputation #####################################################
multinom_res <- 
  df_full %>% 
  multinom(
    arrival_mode ~ service + age + discharge_mode,
    data = .,
    maxit = 200
  )

df_full_filtered <- 
  df_full_filtered %>% 
  bind_cols(
    predict(multinom_res, newdata = df_full_filtered, type = "probs") %>% 
    as_tibble()
  ) %>% 
  rowwise() %>% 
  mutate(
    arrival_mode = case_when(
      is.na(arrival_mode) ~ 
        sample(
          x = c(
            "Ambulance", "Ambulance + firefighters", "Ambulance + life support",
            "Cops", "Helicopter", "Personal"
          ),
          size = 1,
          prob = c(
            Ambulance, `Ambulance + firefighters`, `Ambulance + life support`,
            Cops, Helicopter, Personal
          )
        ),
      .default = arrival_mode
    )
  ) %>% 
  ungroup() %>% 
  select(-c("Ambulance", "Ambulance + firefighters", "Ambulance + life support",
            "Cops", "Helicopter", "Personal"))

## Complexity imputation #######################################################
df_full_filtered_complete <- 
  df_full_filtered %>% 
  filter(!is.na(complexity))
df_full_filtered_missing <- 
  df_full_filtered %>% 
  filter(is.na(complexity))

# Train knn on complete data + predict missing values
knn_res <- 
  kknn(
    factor(complexity, ordered = TRUE) ~ service + age + discharge_mode + arrival_mode,
    train = df_full_filtered_complete,
    test = df_full_filtered_missing,
    k = 7
  )

# Build the original dataset back (with the imputed values)
df_full_filtered <- 
  bind_rows(
    df_full_filtered_complete,
    df_full_filtered_missing %>% 
      mutate(
        # This adds the imputed values
        complexity = as.numeric(knn_res$fitted.values) 
      )
  )
