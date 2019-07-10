using CSV, DataFrames, XGBoost

train = CSV.read("higgs-boson/train.csv")
test = CSV.read("higgs-boson/test.csv")

train_x, train_y = train[:, 2:31], map(i->i == "s" ? 1 : 0, train[:Label])
test_x = test[:, 2:31]

#################################
# Feature Selection + Engineering
#################################

# Phi + Eta Angles
tau_lep_phi
tau_met_phi
tau_jet_leading_phi
lep_met_phi
lep_jet_leading_phi
met_jet_leading_phi
jet_leading_subleading_phi

tau_lep_eta
tau_jet_leading_eta
lep_jet_leading_eta
jet_leading_subleading_eta

# Transverse Momentum Ratios
tau_lep_pt
jet_leading_subleading_pt
met_sumet

# Drop phi due to invariant rotational symmetry
tau_phi, lep_phi, met_phi, jet_leading_phi, jet_subleading_phi
