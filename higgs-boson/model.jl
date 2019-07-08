using CSV, DataFrames, XGBoost

function load_data(filename)
  data = CSV.read(filename)
  return data[:, 1:31], map(i -> i == "s" ? 1 : 0, data[:, 33])
end

train_x, train_y = load_data("higgs-boson/train.csv")
test_x = CSV.read("higgs-boson/test.csv")