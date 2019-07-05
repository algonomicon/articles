using ColorSchemes, CSV, DataFrames, Gadfly, Statistics

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

# Signal/Background distributions
signal, background = groupby(working, :Label)


# Locations of particles
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

# How much energy is missing?
missing_energy = plot(train, x = :PRI_met, color = :Label, Geom.histogram, 
    Guide.colorkey(title = "Label", labels = ["Signal","Background"]),
    Guide.xlabel("Missing Transverse Energy"), Scale.x_log10)

#draw(SVGJS("missing-energy.svg", 6inch, 4inch), missing_energy)

# What role do jets play?

# Make groups based on number of jets
jet_groups = groupby(working, :PRI_jet_num)

for group in jet_groups
    @show describe(group)
end

# Correlation coefficient heatmap for events without missing data
correlations = cor(Matrix(dropmissing(train[:, 1:32])))

spy(correlations, Scale.y_discrete(labels = i->names(train[:, 1:32])[i]),
    Guide.ylabel(nothing), Guide.colorkey(title = "Correlation\nCoefficient  "),
    Guide.xticks(label = false), Guide.xlabel(nothing))
