using ColorSchemes, CSV, DataFrames, Gadfly

Gadfly.push_theme(:dark)

# Exoplanets downloaded from https://exoplanetarchive.ipac.caltech.edu/cgi-bin/TblView/nph-tblView?app=ExoTbls&config=planets
exoplanets = CSV.read("planets_2019.06.07_18.33.16.csv", comment = "#")

# Don't care about url reference links
deletecols!(exoplanets, [:pl_def_reflink, :pl_disc_reflink, :pl_pelink, :pl_edelink])

# Reference planets
planets = DataFrame(name = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"],
                    mass = [0.0553, 0.815, 1, 0.107, 317.8, 95.2, 14.5, 17.1],
                    radius = [0.383, 0.949, 1, 0.532, 11.21, 9.45, 4.01, 3.88],
                    eqt = [449, 328, 279, 226, 122, 90, 64, 51])

# Statistical details of the entire dataset
describe(exoplanets)
describe(planets)

# Mass x Radius
# Scatter plot
scatter = plot(layer(planets, x = :radius, y = :mass, label = :name, Geom.point, Geom.label,
        style(default_color = colorant"white", point_label_color = colorant"white")),
     layer(dropmissing(exoplanets, [:pl_rade, :pl_bmasse]), x = :pl_rade, y = :pl_bmasse),
     Scale.y_sqrt, Guide.xlabel("Radius (Earth Radii)"), Guide.ylabel("Mass (Earth Mass)"))

#draw(SVGJS("mass-radius-scatter.svg", 6inch, 4inch), scatter)

# 2d Density plot
density = plot(layer(planets, x = :radius, y = :mass, label = :name, Geom.point, Geom.label,
           style(default_color = colorant"white", point_label_color = colorant"white")),
     layer(dropmissing(exoplanets, [:pl_rade, :pl_bmasse]), x = :pl_rade, y = :pl_bmasse, Geom.density2d),
     style(key_position = :none), 
     Scale.color_continuous(colormap = x->colorant"#fe4365"),
     Guide.xlabel("Radius (Earth Radii)"), Guide.ylabel("Mass (Earth Mass)"))

#draw(SVGJS("mass-radius-density.svg", 6inch, 4inch), density)

# Relative size
sorted = sort(dropmissing(exoplanets, :pl_rade), :pl_rade)
smallest = first(sorted)
largest = last(sorted)

# Values plotted manually
plot(layer(x = [3.5], y = [0], label = ["Kepler-37 b"], Geom.point, Geom.label, style(point_size = 0.336pt, point_label_color = colorant"white")),
     layer(x = [3], y = [0], label = ["Earth"], Geom.point, Geom.label, style(point_size = 1pt, point_label_color = colorant"white")),
     layer(x = [2.5], y = [0], label = ["Jupiter"], Geom.point, Geom.label, style(point_size = 11.21pt, point_label_color = colorant"white")),
     layer(x = [1], y = [0], label = ["HD 100546 b"], Geom.point, Geom.label, style(point_size = 77.342pt, point_label_color = colorant"white")),
     Scale.y_continuous(minvalue = -200, maxvalue = 200))

#draw(SVGJS("relative-size.svg", 6inch, 4inch), relativeSize)

# How hot are the planets?

temp = plot(dropmissing(exoplanets, [:pl_eqt, :pl_ratdor, :pl_insol]), x = :pl_ratdor, y = :pl_insol, color = :pl_eqt,
     Scale.y_log10, Scale.x_log10, Scale.color_continuous(colormap = (x->get(ColorSchemes.blackbody, x))),
     Guide.xlabel("Ratio of Distance to Star Size"),
     Guide.ylabel("Solar Irradiance (Earth Flux)"),
     Guide.colorkey(title = "Temp (K) "))

draw(SVGJS("equilibrium-temperature.svg", 6inch, 4inch), temp)

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

draw(SVGJS("orbit-grid.svg", 6inch, 4inch), orbits)

# Do they have moons?
exoplanets[exoplanets[:pl_mnum] .> 0, :pl_mnum] |> length

# How big are the host stars?

# How hot are the host stars?

# What are their spectral qualities?

# What are they composed of?

# How old are they?