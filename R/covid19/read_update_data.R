#!/usr/bin/env Rscript

# config
options(warn = -1)
Sys.setenv(TZ = "America/Sao_Paulo")

# packages
require(magrittr, include.only = "%>%", quietly = TRUE)

# read data
covid19 <- 
  read.csv("time_series_covid19_deaths_global.csv")

# prepare data
sa <- 
  covid19 %>% 
  dplyr::filter(Country.Region %in%  c("Brazil", "Peru", "Bolivia", 
                                       "Chile", "Argentina", "Colombia",
                                       "Venezuela", "Ecuador", "Uruguay",
                                       "Paraguay")) %>% 
  dplyr::select(- Province.State) %>% 
  tidyr::pivot_longer(!Country.Region:Long, 
                      names_to = "date", 
                      values_to = "cumulate") %>% 
  dplyr::group_by(Country.Region) %>% 
  dplyr::mutate(date = gsub("X", "", date) %>% 
                  gsub("\\.", "-", .) %>% 
                  lubridate::mdy(),
                value = cumulate - dplyr::lag(cumulate))

avg_sa <- 
  sa %>% 
  dplyr::mutate(week = lubridate::week(date),
                year = lubridate::year(date)) %>% 
  dplyr::group_by(Country.Region, year, week, Lat, Long) %>% 
  dplyr::summarise(avg_value = mean(value, na.rm = TRUE), .groups = "drop") %>% 
  dplyr::group_by(Country.Region) %>%
  dplyr::mutate(delta = (avg_value - dplyr::lag(avg_value))/dplyr::lag(avg_value) * 100) %>% 
  dplyr::rename(country = Country.Region) %>% 
  dplyr::ungroup() %>% 
  dplyr::mutate(delta = ifelse(is.finite(delta) & !is.na(delta), delta, 0))

# write data
require(dbplyr, quietly = TRUE)

readRenviron(".Renviron")

drv <-
  RJDBC::JDBC("com.ibm.db2.jcc.DB2Driver", "jars/db2jcc4.jar")

db2 <-
  DBI::dbConnect(drv,
                 Sys.getenv("DB2_HOST"),
                 user = Sys.getenv("DB2_USER"),
                 password = Sys.getenv("DB2_PASSWORD"))

response <- DBI::dbWriteTable(db2, "AVG_SA_COVID19", value = avg_sa, overwrite = TRUE)

# test
update <- sa %>% dplyr::pull(date) %>% range() %>% .[2]

# response
jsonlite::stream_out(data.frame(return = response,
                                update = update), verbose = FALSE)

