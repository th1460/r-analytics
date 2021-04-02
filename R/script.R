#!/usr/bin/env Rscript

# load model
loaded_model <- 
  tidypredict::as_parsed_model(
    yaml::read_yaml("my_model.yml"))

# input
input <- jsonlite::fromJSON("input.json", flatten = FALSE)

# compute prediction
pred <- tidypredict::tidypredict_to_column(as.data.frame(input), loaded_model)

# output
jsonlite::stream_out(pred, verbose = FALSE)
