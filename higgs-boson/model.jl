using CSV, DataFrames, Statistics, XGBoost

train = CSV.read("higgs-boson/train.csv")
test = CSV.read("higgs-boson/test.csv")

#################################
# Feature Selection + Engineering
#################################

# Absolute differences of phi
delta_phi(ϕ1, ϕ2) = (ϕ1 == -999 || ϕ2 == -999) ? -999.0 : abs(ϕ1 - ϕ2)

train[:ALGO_delta_phi_tau_lep] = delta_phi.(train[:PRI_tau_phi], train[:PRI_lep_phi])
train[:ALGO_delta_phi_tau_jet1] = delta_phi.(train[:PRI_tau_phi], train[:PRI_jet_leading_phi])
train[:ALGO_delta_phi_tau_jet2] = delta_phi.(train[:PRI_tau_phi], train[:PRI_jet_subleading_phi])
train[:ALGO_delta_phi_lep_jet1] = delta_phi.(train[:PRI_lep_phi], train[:PRI_jet_leading_phi])
train[:ALGO_delta_phi_lep_jet2] = delta_phi.(train[:PRI_lep_phi], train[:PRI_jet_subleading_phi])
train[:ALGO_delta_phi_jet1_jet2] = delta_phi.(train[:PRI_jet_leading_phi], train[:PRI_jet_subleading_phi])

test[:ALGO_delta_phi_tau_lep] = delta_phi.(test[:PRI_tau_phi], test[:PRI_lep_phi])
test[:ALGO_delta_phi_tau_jet1] = delta_phi.(test[:PRI_tau_phi], test[:PRI_jet_leading_phi])
test[:ALGO_delta_phi_tau_jet2] = delta_phi.(test[:PRI_tau_phi], test[:PRI_jet_subleading_phi])
test[:ALGO_delta_phi_lep_jet1] = delta_phi.(test[:PRI_lep_phi], test[:PRI_jet_leading_phi])
test[:ALGO_delta_phi_lep_jet2] = delta_phi.(test[:PRI_lep_phi], test[:PRI_jet_subleading_phi])
test[:ALGO_delta_phi_jet1_jet2] = delta_phi.(test[:PRI_jet_leading_phi], test[:PRI_jet_subleading_phi])
 
# Drop phi due to invariant rotational symmetry
train = deletecols(train, [:PRI_tau_phi, :PRI_lep_phi, :PRI_met_phi, :PRI_jet_leading_phi, :PRI_jet_subleading_phi])
test = deletecols(test, [:PRI_tau_phi, :PRI_lep_phi, :PRI_met_phi, :PRI_jet_leading_phi, :PRI_jet_subleading_phi])


##########
# Training
##########

train_w = convert(Vector, train[:Weight])
train_x = convert(Matrix, deletecols(train, [:EventId, :Weight, :Label]))
train_y = convert(Vector, map(i -> i == "s" ? 1 : 0, train[:Label]))

dtrain = DMatrix(train_x, false, -999.0, weight=train_w, label=train_y)
dtest = DMatrix(convert(Matrix, deletecols(test, [:EventId])), false, -999.0)

rounds = 3000

param = Dict(
  "max_depth" => 9,
  "eta" => 0.01,
  "sub_sample" => 0.9,
  "objective" => "binary:logitraw"
)

model = xgboost(
  dtrain,
  rounds,
  param=param,
  metrics=["ams@0.15", "auc"]
)

#########
# Testing
#########

function rank(xs)
  ranks = Array{Int64}(undef, length(xs))
  order = sortperm(xs)

  for i = 1:length(xs)
    ranks[order[i]] = i
  end

  return ranks
end

predictions = predict(model, dtest)
rank_order = rank(predictions)
labels = map(x -> x > .85 * size(test, 1) ? 's' : 'b', rank_order)

#################
# Submission file
#################

submission = DataFrame(EventId=test[:EventId], RankOrder=rank_order, Class=labels)
CSV.write("submission.csv", submission)