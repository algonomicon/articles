using CSV, DataFrames, Gadfly

# Dataset downloaded from https://www.kaggle.com/c/higgs-boson/data
train = CSV.read("higgs-boson/train.csv", missingstring = "-999.0")

# Show dataset statistics
@show describe(train)