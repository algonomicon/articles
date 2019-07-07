using ColorSchemes, CSV, DataFrames, Gadfly

Gadfly.push_theme(:dark)

# Exoplanets downloaded from https://exoplanetarchive.ipac.caltech.edu/cgi-bin/TblView/nph-tblView?app=ExoTbls&config=planets
exoplanets = CSV.read("planets_2019.06.07_18.33.16.csv", comment = "#")

# Don't care about url reference links
deletecols!(exoplanets, [:pl_def_reflink, :pl_disc_reflink, :pl_pelink, :pl_edelink])

# Reference planets
planets = DataFrame(name = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"],
                    mass = [0.0553, 0.815, 1, 0.107, 317.8, 95.2, 14.5, 17.1],
                    radius = [0.383, 0.949, 1, 0.532, 11.21, 9.45, 4.01, 3.88])

# Statistical details of the entire dataset
@show describe(exoplanets)
@show describe(planets)

# How were planets discovered?
discoveries = plot(dropmissing(exoplanets, [:pl_disc, :pl_discmethod]), x = :pl_disc, color = :pl_discmethod, Geom.line, Stat.histogram, 
     Scale.y_sqrt,
     Guide.colorkey(title = "Discovery Method              "),
     Guide.xlabel("Discovery Year"))

#draw(SVGJS("discoveries.svg", 6inch, 4inch), discoveries)

# Where are they?
coordinates = unique(dropmissing(exoplanets, [:st_glon, :st_dist]), [:st_glon, :st_dist])

# Farthest and closest
sorted_distance = sort(dropmissing(exoplanets, [:st_dist]), :st_dist)
describe(sorted_distance[:st_dist])
closest = first(sorted_distance)
farthest = last(sorted_distance)

# Convert polar galactic coordinates to cartesian
x_pos = coordinates[:st_dist] .* cos.(coordinates[:st_glon])
y_pos = coordinates[:st_dist] .* sin.(coordinates[:st_glon])

star_map = plot(layer(x = [0, 8121.9961554], y = [0, -7.90263480146], label = ["Earth", "Galactic Center"], Geom.point, Geom.label, style(default_color = colorant"white", point_label_color = colorant"white")),
     layer(x = x_pos, y = y_pos),
     Guide.xlabel("Distance (Parsecs)"),
     Guide.ylabel("Distance (Parsecs)"))

#draw(SVGJS("star-map.svg", 6inch, 4inch), star_map)

########################
# Planet Characteristics
########################

# Mass Radius Scatter
scatter = plot(layer(planets, x = :radius, y = :mass, label = :name, Geom.point, Geom.label,
        style(default_color = colorant"white", point_label_color = colorant"white")),
     layer(dropmissing(exoplanets, [:pl_rade, :pl_bmasse]), x = :pl_rade, y = :pl_bmasse),
     Scale.y_sqrt, Guide.xlabel("Radius (Earth Radii)"), Guide.ylabel("Mass (Earth Mass)"))

#draw(SVGJS("mass-radius-scatter.svg", 6inch, 4inch), scatter)

# Mass Radius 2d Density
density = plot(layer(planets, x = :radius, y = :mass, label = :name, Geom.point, Geom.label,
           style(default_color = colorant"white", point_label_color = colorant"white")),
     layer(dropmissing(exoplanets, [:pl_rade, :pl_bmasse]), x = :pl_rade, y = :pl_bmasse, Geom.density2d),
     style(key_position = :none), 
     Scale.color_continuous(colormap = x->colorant"#fe4365"),
     Guide.xlabel("Radius (Earth Radii)"), Guide.ylabel("Mass (Earth Mass)"))

#draw(SVGJS("mass-radius-density.svg", 6inch, 4inch), density)

# Relative Size
sorted_size = sort(dropmissing(exoplanets, :pl_rade), :pl_rade)
smallest = first(sorted_size)
largest = last(sorted_size)

plot(layer(x = [3.5], y = [0], label = ["Kepler-37 b"], Geom.point, Geom.label, style(point_size = 0.336pt, point_label_color = colorant"white")),
     layer(x = [3], y = [0], label = ["Earth"], Geom.point, Geom.label, style(point_size = 1pt, point_label_color = colorant"white")),
     layer(x = [2.5], y = [0], label = ["Jupiter"], Geom.point, Geom.label, style(point_size = 11.21pt, point_label_color = colorant"white")),
     layer(x = [1], y = [0], label = ["HD 100546 b"], Geom.point, Geom.label, style(point_size = 77.342pt, point_label_color = colorant"white")),
     Scale.y_continuous(minvalue = -200, maxvalue = 200))

#draw(SVGJS("relative-size.svg", 6inch, 4inch), relativeSize)

# How hot are the planets?
temp = plot(layer(x = [1], y = [5778], color = [255], shape = [Shape.xcross], size = [3pt], label = ["Earth"], Geom.point, Geom.label, style(point_label_color = colorant"white")),
     layer(dropmissing(exoplanets, [:pl_eqt, :st_teff, :pl_orbsmax]), x = :pl_orbsmax, y = :st_teff, color = :pl_eqt),
     Scale.x_log10, Scale.color_continuous(colormap = (x->get(ColorSchemes.blackbody, x))),
     Guide.xlabel("Orbital Semi Major Axis (AU)"), Guide.ylabel("Star Effective Temperature (K)"),
     Guide.colorkey(title = "Planet Equilibrium   \nTemperature (K)  "), Guide.shapekey(pos = [10000,10000]))

#draw(SVGJS("equilibrium-temperature.svg", 6inch, 4inch), temp)

# What do their orbits look like?
semi_major_axis = plot(dropmissing(exoplanets, [:pl_orbsmax]), x = :pl_orbsmax, Geom.histogram(bincount = 50),
     Scale.x_log10, Guide.xlabel("Orbital Semi Major Axis (AU)"))

period = plot(dropmissing(exoplanets, [:pl_orbper]), x = :pl_orbper, Geom.histogram(bincount = 50),
     Scale.x_log10, Guide.xlabel("Orbital Period (Days)"))

eccentricity = plot(dropmissing(exoplanets, [:pl_orbeccen]), x = :pl_orbeccen, Geom.histogram(bincount = 50),
     Guide.xlabel("Eccentricity"))

inclination = plot(dropmissing(exoplanets, [:pl_orbincl]), x = :pl_orbincl, Geom.histogram(bincount = 50),
     Guide.xlabel("Inclination (Deg)"))

orbits = gridstack([semi_major_axis period; eccentricity inclination])

#draw(SVGJS("orbit-grid.svg", 6inch, 4inch), orbits)

# Do they have moons?
exoplanets[exoplanets[:pl_mnum] .> 0, :pl_mnum] |> length

#########################
# Stellar Characteristics
#########################

# How big are they?
star_size = plot(layer(x = [1], y = [1], label = ["Sun"], Geom.point, Geom.label, style(default_color = colorant"white", point_label_color = colorant"white")),
     layer(dropmissing(exoplanets, [:st_rad, :st_mass]), x = :st_rad, y = :st_mass),
     Scale.y_log10, Scale.x_log10,
     Guide.xlabel("Radius (Solar Radii)"),
     Guide.ylabel("Mass (Solar Radii)"))

#draw(SVGJS("star-mass-radius-scatter.svg", 6inch, 4inch), star_size)

# How hot and bright are they?
spectrals = plot(layer(x = [5777], y = [1], label = ["Sun"], color = [5777], size = [3pt], shape = [Shape.xcross], Geom.point, Geom.label(position = :above), style(point_label_color = colorant"white")),
     layer(dropmissing(exoplanets, [:st_lum, :st_teff]), y = :st_lum, x = :st_teff, color = :st_teff),
     Scale.x_log10, Scale.color_continuous(colormap = (x->get(ColorSchemes.blackbody, x))),
     Guide.xlabel("Effective Temperature (K)"), Guide.ylabel("Luminosity (log(Solar))"),
     style(key_position = :none), Coord.cartesian(xflip = true))

#draw(SVGJS("star-temperature-brightness.svg", 6inch, 4inch), spectrals)


# How are age and activity related?
s_activity = plot(dropmissing(exoplanets, [:st_age, :st_acts]), x = :st_age, y = :st_acts, Geom.histogram(bincount = 30))
r_activity = plot(dropmissing(exoplanets, [:st_age, :st_actr]), x = :st_age, y = :st_actr)
x_activity = plot(dropmissing(exoplanets, [:st_age, :st_actlx]), x = :st_age, y = :st_actlx)

activities = vstack([s_activity, r_activity, x_activity])

#draw(SVGJS("star-activity.svg", 6inch, 8inch), activities)

met_fe = plot(dropmissing(exoplanets, [:st_metfe]), x = :st_metfe, Geom.histogram(bincount = 50), Guide.xlabel("Metallicity (Dex)"))
met_ratio = plot(dropmissing(exoplanets, [:st_metratio]), x = :st_metratio, Geom.histogram, Guide.xlabel("Metallicity Ratio"))

metallicity = hstack([met_fe, met_ratio])

draw(SVGJS("star-metallicity.svg", 6inch, 4inch), metallicity)
