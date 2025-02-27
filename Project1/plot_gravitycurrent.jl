
# This script reads in output from gravitycurrent.jl, makes a plot, and saves an animation

using JLD2, Plots, Printf

# Set the filename (without the extension)
filename="gravitycurrent"

# Read in the first iteration.  We do this to load the grid
# filename * ".jld2" concatenates the extension to the end of the filename
u_ic=FieldTimeSeries(filename * ".jld2","u",iterations = 0)
v_ic=FieldTimeSeries(filename * ".jld2","v",iterations = 0)
w_ic=FieldTimeSeries(filename * ".jld2","w",iterations = 0)
b_ic=FieldTimeSeries(filename * ".jld2","b",iterations = 0)

## Load in coordinate arrays
## We do this separately for each variable since Oceananigans uses a staggered grid
xu, yu, zu = nodes(u_ic)
xv, yv, zv = nodes(v_ic)
xw, yw, zw = nodes(w_ic)
xb, yb, zb = nodes(b_ic)

## Now, open the file with our data
file_xz = jldopen(filename * ".jld2")

## Extract a vector of iterations
iterations = parse.(Int, keys(file_xz["timeseries/t"]))

@info "Making an animation from saved data..."

t_save=zeros(length(iterations))
b_bottom=zeros(length(b_ic[:,1,1]),length(iterations))

# Here, we loop over all iterations
anim = @animate for (i, iter) in enumerate(iterations)

    @info "Drawing frame $i from iteration $iter..."

    u_xz = file_xz["timeseries/u/$iter"][:, 1, :];
    v_xz = file_xz["timeseries/v/$iter"][:, 1, :];
    w_xz = file_xz["timeseries/w/$iter"][:, 1, :];
    b_xz = file_xz["timeseries/b/$iter"][:, 1, :];

# If you want an x-y slice, you get get it this way:
    # b_xy = file_xy["timeseries/b/$iter"][:, :, 1];

    t = file_xz["timeseries/t/$iter"];

    # Save some variables to plot at the end
    b_bottom[:,i]=b_xz[:,1,1]; # This is the buouyancy along the bottom wall
    t_save[i]=t # save the time

        u_xz_plot = Plots.heatmap(xu, zu, u_xz'; color=:balance, xlabel="x", ylabel="z");  
        v_xz_plot = Plots.heatmap(xv, zv, v_xz'; color=:balance, xlabel="x", ylabel="z"); 
        w_xz_plot = Plots.heatmap(xw, zw, w_xz'; color=:balance, xlabel="x", ylabel="z"); 
        b_xz_plot = Plots.heatmap(xb, zb, b_xz'; color=:thermal, xlabel="x", ylabel="z"); 

    u_title = @sprintf("u (m s⁻¹), t = %s", prettytime(t));
    v_title = @sprintf("v (m s⁻¹), t = %s", prettytime(t));
    w_title = @sprintf("w (m s⁻¹), t = %s", prettytime(t));
    b_title = @sprintf("b (m s⁻²), t = %s", prettytime(t));

# Combine the sub-plots into a single figure
    Plots.plot(u_xz_plot, w_xz_plot, b_xz_plot, layout=(3, 1), size=(1600, 400),
    title=[u_title w_title b_title])

    iter == iterations[end] && close(file_xz)
end

# Save the animation to a file
mp4(anim, "gravitycurrent.mp4", fps = 20) # hide

# Now, make a plot of our saved variables
# In this case, plot the buoyancy at the bottom of the domain as a function of x and t
# You can (and should) change this to interrogate other quantities
Plots.heatmap(xb, t_save, b_bottom', xlabel="x", ylabel="t", title="buoyancy at z=0")
