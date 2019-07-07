using ColorSchemes, CSV, DataFrames, Gadfly, Statistics

Gadfly.push_theme(:dark)

# Dataset downloaded from https://www.kaggle.com/c/higgs-boson/data
train = CSV.read("higgs-boson/train.csv", missingstring = "-999.0")
describe(train)

# Working dataframe with extraneous columns removed
missingcols = [:EventId,
               :DER_mass_MMC,
               :DER_deltaeta_jet_jet,
               :DER_mass_jet_jet,
               :DER_prodeta_jet_jet,
               :DER_lep_eta_centrality,
               :PRI_jet_leading_pt,
               :PRI_jet_leading_eta,
               :PRI_jet_leading_phi,
               :PRI_jet_subleading_pt,
               :PRI_jet_subleading_eta,
               :PRI_jet_subleading_phi]

working = deletecols(train, missingcols)

#################################
# Signal/Background distributions
#################################

signal, background = groupby(working, :Label)

function boxplot_stats(v)
    q1 = quantile(v, 0.25)
    q2 = quantile(v, 0.5)
    q3 = quantile(v, 0.75)

    lf = q1 - (1.5 * (q3 - q1))
    uf = q3 + (1.5 * (q3 - q1))

    return (lf, q1, q2, q3, uf)
end

# Construct combined dataframe by looping over columns
sb_stats = DataFrame(name = [], label = [], lf = [], lh = [], m = [], uh = [], uf = [])

for i in 1:20
    stats = boxplot_stats(signal[:, i])
    push!(sb_stats, [names(signal)[i], "s", stats...])

    stats = boxplot_stats(background[:, i])
    push!(sb_stats, [names(background)[i], "b", stats...])
end

sb_plot = plot(sb_stats, x = :name, lower_fence = :lf, lower_hinge = :lh, middle = :m, upper_hinge = :uh, upper_fence = :uf, color = :label,
    Stat.identity, Geom.boxplot, Guide.xlabel(nothing), style(boxplot_spacing = -10px), Guide.colorkey(title = "", labels = ["Signal", "Background"]))

# draw(SVGJS("sb-stats.svg", 6inch, 4inch), sb_plot)

########################
# Locations of particles
########################

function cartesian(pt, ϕ, η)
    x = pt * cos(ϕ)
    y = pt * sin(ϕ)
    z = pt * sinh(η)

    return (x, y, z)
end

coordinates = DataFrame(x = [], y = [], z = [])

for row in eachrow(working)
    push!(coordinates, cartesian(row[:PRI_tau_pt], row[:PRI_tau_phi], row[:PRI_tau_eta]))
    push!(coordinates, cartesian(row[:PRI_lep_pt], row[:PRI_lep_phi], row[:PRI_lep_eta]))
end

coordinate_density = plot(coordinates, x = :x, y = :y, Geom.density2d,
    Scale.color_continuous(colormap = x->get(ColorSchemes.blackbody, x)))

# draw(SVGJS("coordinate-density.svg", 6inch, 4inch), coordinate_density)

#########################
# What role do jets play?
#########################

jet_groups = groupby(working, :PRI_jet_num, sort = true)
jet_df = DataFrame(num_jets = [], num_s = [], num_b = [])

for group in jet_groups
    num_jets = first(group[:PRI_jet_num])
    num_s = count(group[:Label] .== "s")
    num_b = count(group[:Label] .== "b")

    push!(jet_df, (num_jets, num_s, num_b))

    # Ratio of signal to background
    println("$num_jets: $(num_s / num_b)")
end

jet_plot = plot(stack(jet_df, [:num_s, :num_b]), x = :num_jets, y = :value, color = :variable, Geom.bar(position = :dodge))

# draw(SVGJS("num-jets.svg", 6inch, 4inch), jet_plot)

#################
# Energy and Mass
#################

# Total energy by missing transverse energy
energy = plot(working, x = :PRI_met_sumet, y = :PRI_met, Geom.histogram2d,
    Scale.y_log10, Guide.xlabel("Total Transverse Energy"), Guide.ylabel("Missing Transverse Energy"))

draw(SVGJS("transverse-energy.svg", 6inch, 4inch), energy)

# Mass comparisons
higgs_candidates = dropmissing(train, :DER_mass_MMC)

invariant_mass = plot(higgs_candidates, x = :DER_mass_MMC, y = :DER_mass_vis, Geom.histogram2d, Guide.xlabel("Higgs Candidate Mass"), Guide.ylabel("Invariant Mass"))

draw(SVGJS("higgs-invariant-mass.svg", 6inch, 4inch), invariant_mass)


#######################
# Attribute Corrlations
#######################

# Correlation coefficient heatmap for events without missing data
correlations = cor(Matrix(working[:, 1:20]))

corrrelation_plot = spy(correlations, Scale.y_discrete(labels = i->names(working[:, 1:20])[i]),
    Guide.ylabel(nothing), Guide.colorkey(title = "Correlation\nCoefficient  "),
    Guide.xticks(label = false), Guide.xlabel(nothing))

# draw(SVGJS("correlations.svg", 6inch, 4inch), corrrelation_plot)


######################################

# Makie 3d Plots

# tau_coordinates = Point3f0[]
# lep_coordinates = Point3f0[]

# for row in eachrow(train)
#     push!(tau_coordinates, cartesian(row[:PRI_tau_pt], row[:PRI_tau_phi], row[:PRI_tau_eta]))
#     push!(lep_coordinates, cartesian(row[:PRI_lep_pt], row[:PRI_lep_phi], row[:PRI_lep_eta]))
# end

# scene = Scene(resolution = (1200, 800), backgroundcolor = "#222831")
# scatter!(scene, tau_coordinates, markersize = 5, color = "#fe4365")
# scatter!(scene, lep_coordinates, markersize = 5, color = "#eca25c")

# save("coordinates.png", scene)

######################################