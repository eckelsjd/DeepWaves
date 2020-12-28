# Los Alamos Dynamics Summer School (LADSS)
# Team: DeepWaves
# Date: 8/17/2020
# Author: Joshua Eckels, Kelly Ho, Isabel Fernandez
# Description:
# Python script to load all geometry files and run through Ansys simulation script.
# Run this script from top-level Ansys workbench->scripting.
# Only tested on Ansys 19.1
# Calls subprocess to run Matlab script and upload results to dropbox

import os
import shutil
# import subprocess

# SIM setup_script beforehand:
	# load aluminum material
	# Insert APDL commands
	# Insert Directional Deformation
	# Insert Pressure
	# Use 4 physical cores (virtual cores not recommended)
	# Tools->Solve Process Settings->Advanced->number of cores
	# Use NVIDIA GPU speedup if you have a recommended GPU
	
# TODO: Create setup script to make project from scratch

# Set this to the base path of the project
SetUserPathRoot(DirectoryPath="C:\Users\eckelsjd\git_projects\DeepWaves")
os.chdir(AbsUserPathName("src"))

# Filepath for matlab+dropbox script
matlab_script = AbsUserPathName("src/run_matlab.py")

# Open project
projPath = AbsUserPathName("ansys/DeepWaves.wbpj")
Open(FilePath=projPath)
ClearMessages()
logfile = open(AbsUserPathName("output/logs/run_sims.log"),"w")
logfile.write("Processing project in " + projPath + "\n")

# Get harmonic system object
harmonicSys = GetSystem(Name="SYS")

# Open Ansys Mechanical GUI
modelComponent = harmonicSys.GetComponent(Name="Model")
mech = harmonicSys.GetContainer(ComponentName="Model")
mech.Edit()

# Load ACT mechanical script
act_script = open(AbsUserPathName("src/ACT_mech_script.py"),"r")
act_command = act_script.read()
act_script.close()

# Open geometry container
try:
	geometry = harmonicSys.GetContainer(ComponentName="Geometry")
except:
	logfile.write("No geometry to replace in system " + system.DisplayText + "\n")
	
# Gather list of .step files from geometry folder
stepFiles = os.listdir(AbsUserPathName("geometry"))
logfile.write("Gathering step files:\n")
for geom in stepFiles:
	if not ".step" in geom.lower():
		logfile.write(geom + "is not a .step file. Continuing...\n")
		continue
	newGeom = AbsUserPathName("geometry/" + geom)
	logfile.write("Opening " + newGeom + "\n")
	
	# Open new geometry
	geometry.SetFile(FilePath=newGeom)
	
	# Refresh and run ACT script in Mechanical
	modelComponent.Refresh()
	mech.SendCommand(Command=act_command,Language="Python")
	
	# Retrieve and rename output .txt files
	outputPath = AbsUserPathName("ansys/DeepWaves_files/dp0/SYS/MECH/")
	# outputImag = AbsUserPathName(outputPath + "imaginary.txt")
	# outputReal = AbsUserPathName(outputPath + "real.txt")
	outputDisp = AbsUserPathName(outputPath + "disp.txt")
	
	# imagFilename = os.path.splitext(geom)[0] + "_imaginary.txt"
	# imagPath = AbsUserPathName("data/" + imagFilename)
	# realFilename = os.path.splitext(geom)[0] + "_real.txt"
	# realPath = AbsUserPathName("data/" + realFilename)
	dispFilename = os.path.splitext(geom)[0] + "_disp.txt"
	dispPath = AbsUserPathName("data/" + dispFilename)
	
	# shutil.move(outputImag,imagPath)
	# shutil.move(outputReal,realPath)
	shutil.move(outputDisp,dispPath)
	
	# Plot wavefield with Matlab and upload to dropbox
	cmd = "python %s %s" % (matlab_script,dispFilename)
	os.system(cmd)
	# process = subprocess.run(['python',matlab_script,realFilename,imagFilename,"visual"],stdout=subprocess.PIPE,universal_newlines = True)

# Cleanup
mech.Exit()
logfile.write("\n")
logfile.close()
Save(FilePath=AbsUserPathName("ansys/DeepWaves.wbpj"),Overwrite=True)

##### Maybe not needed code snippets #####

# Update the project
# Update()
# if IsProjectUpToDate():
#	logfile.write("Parameter values in revised project:\n")
#	writeParams(logfile)
#else:
#	logfile.write("ERROR: Project not successfully updated. The following messages were found:\n")
#	for msg in GetMessages():
#		msgString = "  " + msg.DateTimeStamp.ToString() + " " + msg.MessageType + ": " + msg.Summary + "\n"
#		logfile.write(msgString + "\n")

# Load material data (not working)
# engineeringData = harmonicSys.GetContainer(ComponentName="Engineering Data")
# alum = engineeringData.ImportMaterial(
#    Name="Aluminum Alloy",
#    Source="General_Materials.xml")

#def writeParams(logfile):
#	for param in Parameters.GetAllParameters():
#		prmString = " " + param.Name + ": " + param.DisplayText + " = " + param.Value.ToString()
#		logfile.write(prmString + "\n")
#	logfile.flush()

#logfile.write("Parameter values in original project:\n")
#writeParams(logfile)
