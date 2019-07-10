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
delta_phi_tau_lep
delta_phi_tau_jet1
delta_phi_tau_jet2
delta_phi_lep_jet1
delta_phi_lep_jet2
delta_phi_jet1_jet2

# Delta Eta angles
delta_eta_tau_lep
delta_eta_tau_jet1
delta_eta_tau_jet2
delta_eta_lep_jet1
delta_eta_lep_jet2
delta_eta_jet1_jet2
 
# Drop phi due to invariant rotational symmetry
tau_phi, lep_phi, met_phi, jet1_phi, jet2_phi

# Take absolute values of eta
tau_eta, lep_eta, jet1_eta, jet2_eta

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
