# # Quickstart - Artifact simulation

# Artifact simulation builds on the basic EEG simulation (see the Quickstart tutorial). 
# In addition to the design, components, onset and noise required to simulate EEG, the user needs to provide at least one artifact signal: for example, an eye movement artifact, a power line noise artifact, or a drift artifact. 

# ## Specify the simulation ingredients

# ### Setup
# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
## Load required packages
using UnfoldSim
using Random # to get an RNG
using CairoMakie # for plotting

# ```@raw html
# </details >
# ```

# ### Set up EEG simulation
# Set up the basic ingredients for simulating EEG and noise: design, component, onset, and noise. For the currently available artifact simulation, 
# the EEG simulation component must be set up to generate multichannel data rather than single channel data. 
# The artifact simulation runs under the assumption that the EEG and artifacts all have the same number of channels simulated.

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
    design = SingleSubjectDesign(; conditions = Dict(:cond_A => ["level_A", "level_B"])) |> x -> RepeatDesign(x, 10);
    signal = LinearModelComponent(;
    basis = [0, 0, 0, 0.5, 1, 1, 0.5, 0, 0],
    formula = @formula(0 ~ 1 + cond_A),
    β = [1, 0.5],
    );
    hart = Hartmut();
    mc = UnfoldSim.MultichannelComponent(signal, hart => "Left Postcentral Gyrus");
    onset = UniformOnset(; width = 20, offset = 4);
    noise = PinkNoise(; noiselevel = 0.2);

# ```@raw html
# </details >
# ```

# ### Set up the forward model and sample gaze vectors for the eye movement


# Import hartmut model - modified with new eye points
eyemodel = UnfoldSim.import_eyemodel()

# Import href gaze coordinates
sample_data = UnfoldSim.example_data_eyemovements();
href_trajectory = sample_data[1:2,1:20];

# ### Simulate EEG with multiple artifacts (Eye movement, noise, power line noise)

# The simulate function returns the summed simulated signal, the events from the simulation and a vector containing the EEG and all the individual noise signals simulated, in the order in which they are passed to the simulate function. 

eeg_artifacts, events, split_elements = simulate(MersenneTwister(1), design, mc, onset, [UnfoldSim.EyeMovement(UnfoldSim.HREFCoordinates(href_trajectory), eyemodel, "ensemble"); noise; UnfoldSim.PowerLineNoise()]);


# You can plot the eeg (just one channel, for convenience):
lines(eeg_artifacts[1,:]; color="green")
current_axis().title = "Simulated EEG data"
current_axis().xlabel = "Time [samples]"
current_axis().ylabel = "Amplitude [μV]"

current_figure()


# It seems to be dominated by the power line noise - let's look at all the parts separately (in order: EEG, eye movement artifact, noise, power line noise).

f = Figure()
lines(f[1, 1], split_elements[1][1, :];)
lines(f[1, 2], split_elements[2][1, :];)
lines(f[2, 1], split_elements[3][1, :];)
lines(f[2, 2], split_elements[4][1, :];)
f