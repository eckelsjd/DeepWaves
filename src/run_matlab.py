# Los Alamos Dynamics Summer School (LADSS)
# Team: DeepWaves
# Date: 8/17/2020
# Author: Joshua Eckels (eckelsjd@rose-hulman.edu)
# Description:
# Python script to call a Matlab function and then move all result files
# to dropbox teams folder (to save hard drive space)
# Comment out dropbox calls to ignore this

import matlab.engine
import sys
import os
import dropbox
from dropbox.files import WriteMode
from dropbox.exceptions import ApiError, AuthError
from pathlib import Path

# Private token to access Dropbox account (see Dropbox API help)
TOKEN = ""

# Function to call Matlab plot_wavefield.m
def exec_matlab(filename):
	print("Starting MATLAB for you :)")
	eng = matlab.engine.start_matlab()
	t_out = eng.plot_wavefield(filename,nargout=1)
	print("plot_wavefield completed. Your images are saved to hard drive.")
	print("Closing MATLAB...")

# Upload src file to dest location in Dropbox team folder	
def upload(src,dest):
	print("Creating a Dropbox object...")
	with dropbox.Dropbox(TOKEN) as dbx:
	
		# Find the namespace id of the team from account.root_info
		dbx = dbx.with_path_root(dropbox.common.PathRoot.namespace_id("8057807376"))
		
		# check that the access token is valid
		try:
			account = dbx.users_get_current_account()
			# print(account.root_info)
			# print(account.team)
		except AuthError:
			sys.exit("ERROR: Invalid access token")
		
		with open(src,'rb') as f:
			print("Uploading " + src + " to Dropbox as " + dest + "...")
			try:
				dbx.files_upload(f.read(),dest,mode=WriteMode('overwrite'))
			except ApiError as err:
				if (err.error.is_path() and err.error.get_path().reason.is_insufficient_space()):
					sys.exit("ERROR: Cannot back up; insufficient space")
				elif err.user_message_text:
					print(err.user_message_text)
					sys.exit()
				else:
					print(err)
					sys.exit()
		
		print("Done!")
		
	
# Real and imaginary .txt filenames passed in as argv[1] and argv[2] for matlab
if __name__ == '__main__':
	print("run_matlab.py activated! Welcome.\n")
	# Read command-line arguments
	# real_filename = sys.argv[1]
	# imag_filename = sys.argv[2]
	# mode = sys.argv[3]
	disp_filename = sys.argv[1]
	
	# Generate wavefield images from .txt data
	exec_matlab(disp_filename)

	# Run CNN inference

	# Run MATLAB metrics

	# Display/save MATLAB metrics
	
	# Setup src and dest for dropbox file transfer
	# tokens = real_filename.split('_')
	# round = tokens[0]
	
	# src directories
	# base_src = Path(os.getcwd())/'..'
	# src_data = base_src/'data'
	# src_images = base_src/'images'
	# src_labels = base_src/'labels'
	
	# dest directories (dropbox relative)
	# base_dest = Path('/datastore')/round
	# dest_data = base_dest/(round+'_data')
	# dest_images = base_dest/(round+'_images')
	# dest_labels = base_dest/(round+'_labels')
	
	# Image filenames
	# real_image = os.path.splitext(real_filename)[0] + '.png'
	# imag_image = os.path.splitext(imag_filename)[0] + '.png'
	# mask_image = real_filename.split('_real.txt')[0] + '_mask.png'
	# mag_image = real_filename.split('_real.txt')[0] + '_magnitude.png'
	
	# Upload files to dropbox
	# print("Moving your files to Dropbox: \n")
	# upload(str(src_data/real_filename),(dest_data/real_filename).as_posix()) # Real data.txt
	# upload(str(src_data/imag_filename),(dest_data/imag_filename).as_posix()) # Imaginary data.txt
	# upload(str(src_images/real_image), (dest_images/real_image).as_posix())  # Real image.png
	# upload(str(src_images/imag_image), (dest_images/imag_image).as_posix())  # Imaginary image.png
	# upload(str(src_images/mag_image),(dest_images/mag_image).as_posix())     # Magnitude image.png
	# upload(str(src_labels/mask_image), (dest_labels/mask_image).as_posix())  # Mask image.png
	
	# Remove files from hard drive
	# print("Clearing your hard drive...don't worry. Dropbox has your files now.")
	# os.remove(src_data/real_filename)
	# os.remove(src_data/imag_filename)
	# os.remove(src_images/real_image)
	# os.remove(src_images/imag_image)
	# os.remove(src_images/mag_image)
	# os.remove(src_labels/mask_image)
	print("All done!")