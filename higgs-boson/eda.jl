using CSV, DataFrames, Gadfly, Statistics

# Dataset downloaded from https://www.kaggle.com/c/higgs-boson/data
train = CSV.read("higgs-boson/train.csv", missingstring = "-999.0")

# Dataset statistics
describe(train)

# Primitive values (Skipping jet fields that have many missing values)
primitives = train[:, [:PRI_tau_pt, :PRI_tau_eta, :PRI_tau_phi,
                       :PRI_lep_pt, :PRI_lep_eta, :PRI_lep_phi,
                       :PRI_met, :PRI_met_phi, :PRI_met_sumet,
                       :PRI_jet_num, :PRI_jet_all_pt]]

# 3d plots with Makie
#
# function cartesian(label, pt, ϕ, η)
#     x = pt * cos(ϕ)
#     y = pt * sin(ϕ)
#     z = pt * sinh(η)

#     return (label, x, y, z)
# end

# coordinates = DataFrame(label=[], x = [], y = [], z = [])

# for row in eachrow(primitives)
#     push!(coordinates, cartesian(:circle, row[:PRI_tau_pt], row[:PRI_tau_phi], row[:PRI_tau_eta]))
#     push!(coordinates, cartesian(:x, row[:PRI_lep_pt], row[:PRI_lep_phi], row[:PRI_lep_eta]))
# end

# test_points = coordinates[:, 2:4]
# test_points = [(row[1], row[2], row[3]) for row in eachrow(test_points)]

# scene = Scene(resolution = (500, 500))
# scatter!(scene, test_points, markersize=5)

# Derived values (Skipping fields that have many missing values)
derived = train[:, [:DER_mass_vis, :DER_pt_h,
                    :DER_deltar_tau_lep, :DER_pt_tot,
                    :DER_sum_pt, :DER_pt_ratio_lep_tau, :DER_met_phi_centrality,
                    :DER_mass_transverse_met_lep]]

# Correlation coefficient heatmap
correlations = cor(Matrix(hcat(primitives, derived)))

spy(correlations, Scale.y_discrete(labels = i->vcat(names(primitives), names(derived))[i]),
    Guide.ylabel(nothing), Guide.colorkey(title = "Correlation\nCoefficient  "),
    Guide.xticks(label = false), Guide.xlabel(nothing))
