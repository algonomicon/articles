using CSV, DataFrames, Statistics, XGBoost

train = CSV.read("higgs-boson/train.csv")
test = CSV.read("higgs-boson/test.csv")

train_x, train_y, train_w = train[:, 2:31], map(i -> i == "s" ? 1 : 0, train[:Label]), train[:Weight]
test_x = test[:, 2:31]

###############################
# OG Model (Baseline benchmark)
###############################

rounds = 1000

og_model = xgboost(
  convert(Matrix, train_x),
  rounds, 
  label=train_y, 
  max_depth=9, 
  eta=0.1, 
  sub_sample=0.9,  
  objective="binary:logistic", 
  metrics=["auc"]
)

og_predictions = predict(og_model, convert(Matrix, train_x))

#################################
# Feature Selection + Engineering
#################################

# Absolute differences of phi mapped to [-pi, pi]
delta_phi(ϕ1, ϕ2) = (ϕ1 == -999 || ϕ2 == -999) ? 0 : rem2pi(abs(ϕ1 - ϕ2), RoundNearest)

train_x[:ALGO_delta_phi_tau_lep] = delta_phi.(train_x[:PRI_tau_phi], train_x[:PRI_lep_phi])
train_x[:ALGO_delta_phi_tau_jet1] = delta_phi.(train_x[:PRI_tau_phi], train_x[:PRI_jet_leading_phi])
train_x[:ALGO_delta_phi_tau_jet2] = delta_phi.(train_x[:PRI_tau_phi], train_x[:PRI_jet_subleading_phi])
train_x[:ALGO_delta_phi_lep_jet1] = delta_phi.(train_x[:PRI_lep_phi], train_x[:PRI_jet_leading_phi])
train_x[:ALGO_delta_phi_lep_jet2] = delta_phi.(train_x[:PRI_lep_phi], train_x[:PRI_jet_subleading_phi])
train_x[:ALGO_delta_phi_jet1_jet2] = delta_phi.(train_x[:PRI_jet_leading_phi], train_x[:PRI_jet_subleading_phi])

# Absolute differences of eta
delta_eta(η1, η2) = (η1 == -999 || η2 == -999) ? 0 : abs(η1 - η2)

train_x[:ALGO_delta_eta_tau_lep] = delta_eta.(train_x[:PRI_tau_eta], train_x[:PRI_lep_eta])
train_x[:ALGO_delta_eta_tau_jet1] = delta_eta.(train_x[:PRI_tau_eta], train_x[:PRI_jet_leading_eta])
train_x[:ALGO_delta_eta_tau_jet2] = delta_eta.(train_x[:PRI_tau_eta], train_x[:PRI_jet_subleading_eta])
train_x[:ALGO_delta_eta_lep_jet1] = delta_eta.(train_x[:PRI_lep_eta], train_x[:PRI_jet_leading_eta])
train_x[:ALGO_delta_eta_lep_jet2] = delta_eta.(train_x[:PRI_lep_eta], train_x[:PRI_jet_subleading_eta])
train_x[:ALGO_delta_eta_jet1_jet2] = delta_eta.(train_x[:PRI_jet_leading_eta], train_x[:PRI_jet_subleading_eta])
 
# Drop phi due to invariant rotational symmetry
train_x = deletecols(train_x, [:PRI_tau_phi, :PRI_lep_phi, :PRI_met_phi, :PRI_jet_leading_phi, :PRI_jet_subleading_phi])

# Change all missing instances of -999 to 0
# Borrowing this technique from Gabor Melis (first place finisher)
# http://proceedings.mlr.press/v42/meli14.pdf
train_x = mapcols(col -> replace(col, -999 => 0), train_x)

###############
# Normalization
###############

# Mean centered at 0 with a standard deviation of 1
function normalize(xs)
  μ = mean(xs)
  σ = std(xs)
  return map(x -> ((x - μ) / σ), xs)
end

train_x = mapcols(col -> normalize(col), train_x)

##########
# Training
##########

rounds = 1000

model = xgboost(
  convert(Matrix, train_x),
  rounds, 
  label=train_y, 
  max_depth=9, 
  eta=0.1, 
  sub_sample=0.9,  
  objective="binary:logistic", 
  metrics=["auc"]
)

predictions = predict(model, convert(Matrix, train_x))

#############################
# Baseline Comparison Testing
#############################

# Function to calculate approximate median significance (AMS)
function score(predictions, labels, weights)
  threshold = 0.5
  s = 0
  b = 0

  for i = 1:length(predictions)
    # Only events predicted to be signal are counted
    if predictions[i] > threshold
      (labels[i] == 1) ? (s += weights[i]) : (b += weights[i])
    end
  end

  return sqrt(2 * ((s + b + 10) * log(1 + (s / (b + 10))) - s))
end

println("AMS: ", score(og_predictions, train_y, train_w))
println("AMS: ", score(predictions, train_y, train_w))

#############
# Final Model
#############

rounds = 3000

final_model = xgboost(
  convert(Matrix, train_x),
  rounds, 
  label=train_y, 
  max_depth=9, 
  eta=0.1, 
  sub_sample=0.9,  
  objective="binary:logistic", 
  metrics=["auc"]
)

final_predictions = predict(model, convert(Matrix, test_x))

#################
# Submission file
#################

submission = Dict()