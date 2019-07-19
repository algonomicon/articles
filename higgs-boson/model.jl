using CSV, DataFrames, XGBoost

train = CSV.read("higgs-boson/train.csv")
test = CSV.read("higgs-boson/test.csv")

train_x, train_y = train[:, 2:31], map(i->i == "s" ? 1 : 0, train[:Label])
test_x = test[:, 2:31]

#################################
# Feature Selection + Engineering
#################################

# Delta phi angles
# Map to [-pi, pi]

# Take the difference of the angles in radians and return the difference between them [0, 2pi]
# If angle is -999, the measurement doesn't exist, so return 0
delta_phi(∠1, ∠2) = (∠1 == -999 || ∠2 == -999) ? 0 : rem2pi(abs(∠1 - ∠2), RoundNearest)

train_x[:ALGO_delta_phi_tau_lep] = delta_phi.(train_x[:PRI_tau_phi], train_x[:PRI_lep_phi])
train_x[:ALGO_delta_phi_tau_jet1] = delta_phi.(train_x[:PRI_tau_phi], train_x[:PRI_jet_leading_phi])
train_x[:ALGO_delta_phi_tau_jet2] = delta_phi.(train_x[:PRI_tau_phi], train_x[:PRI_jet_subleading_phi])
train_x[:ALGO_delta_phi_lep_jet1] = delta_phi.(train_x[:PRI_lep_phi], train_x[:PRI_jet_leading_phi])
train_x[:ALGO_delta_phi_lep_jet2] = delta_phi.(train_x[:PRI_lep_phi], train_x[:PRI_jet_subleading_phi])
train_x[:ALGO_delta_phi_jet1_jet2] = delta_phi.(train_x[:PRI_jet_leading_phi], train_x[:PRI_jet_subleading_phi])

# Absolute values of eta

abs_eta(∠) = ∠ == -999 ? 0 : abs(∠)

train_x[:ALGO_tau_abs_eta] = abs_eta.(train_x[:PRI_tau_phi])
train_x[:ALGO_lep_abs_eta] = abs_eta.(train_x[:PRI_lep_phi])
train_x[:ALGO_jet1_abs_eta] = abs_eta.(train_x[:PRI_jet_leading_phi])
train_x[:ALGO_jet2_abs_eta] = abs_eta.(train_x[:PRI_jet_subleading_phi])
 
# Drop phi due to invariant rotational symmetry
delete!(train_x, [:PRI_tau_phi, :PRI_lep_phi, :PRI_met_phi, :PRI_jet_leading_phi, :PRI_jet_subleading_phi])


###############
# Normalization
###############

# Center everything around mean of 0 and std dev of 1

###################
# Raw Feature Model
###################

# rounds = 2
# model = xgboost(convert(Matrix, train_x), rounds, label = train_y, eta = 1, max_depth = 2)
# predictions = predict(model, train_x)

# Test error
# rmse or ams (higgs eval metric)

# Cross validation
# nfolds = 5
# params = Dict("max_depth" => 2, 
#               "eta" => 1,
#               "objective" => "binary:logistic")

# folded_model = nfold_cv(train_x, rounds, label = train_y, param = params, metrics = ["auc"])
