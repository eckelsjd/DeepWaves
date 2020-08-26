# Los Alamos Dynamics Summer School (LADSS)
# Team: DeepWaves
# Date: 8/17/2020
# Author: Joshua Eckels, Kelly Ho, Isabel Fernandez
# Description:
# Python script to run in Ansys 19.1 Mechanical
# Builds and runs simulation for plate geometry in DeepWaves project

# Get access to the geometry
model = ExtAPI.DataModel.Project.Model
part = model.Geometry.Children[0]
body = part.Children[0]
body.Assignment = "Aluminum Alloy"

# Generate mesh
mesh = model.Mesh
mesh.ElementSize = Quantity("2 [mm]")
mesh.GenerateMesh()

# Get top transducer face to apply pressure
# Transducer face must be at the greatest z-value
faces = body.GetGeoBody().Faces
zmax = 0
for i in range(0,len(faces)):
	face = faces[i]
	centroid = face.Centroid
	if centroid[2] > zmax:
		zmax = centroid[2]
		transducer = face
		
# Select the transducer face
selection = ExtAPI.SelectionManager.CreateSelectionInfo(SelectionTypeEnum.GeometryEntities)
selection.Entities = [transducer]

# Edit transducer pressure
pressure = model.Analyses[0].Children[2]
pressure.Location = selection
pressure.Magnitude.Output.DiscreteValues = [Quantity("100000 [Pa]")]

# Edit Directional Deformation solution analysis object
selection.Entities = [body.GetGeoBody().Part.Bodies[0]]
sol = model.Analyses[0].Children[3]
deform = sol.Children[1]
deform.Location = selection
deform.NormalOrientation = NormalOrientationType.ZAxis

# Edit Analysis Settings
analysisSettings = model.Analyses[0].Children[1]
analysisSettings.RangeMaximum = Quantity("80000 [Hz]")
analysisSettings.SolutionMethod = HarmonicMethod.Full
analysisSettings.SolutionIntervals = 1
analysisSettings.ConstantDampingRatio = 0.001
analysisSettings.StructuralDampingCoefficient = Quantity("0.001 [rad/s]")

# Run the simulation
model.Solve(True)

# Notes:
# ExtAPI.DataModel.Project gives access to full tree in Mechanical GUI outline
# Model.Analyses[0:] gives list of "system" blocks in Workbench
# In this case, Model.Analyses[0] gives the Harmonic Response system
# Analyses[0].Children[0:] gives all items underneath Harmonic response in the outline