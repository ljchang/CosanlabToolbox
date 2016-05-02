'''
This Script converts nifti image in talaraich space to MNI using Lancaster, 2007 HBM affine matrix
"Bias Between MNI and Talairach CoordinatesAnalyzed Using the ICBM-152 Brain Template"
http://www.brainmap.org/icbm2tal/
'''

from neurosynth.base.dataset import Dataset
from neurosynth.analysis import meta, decode, network, plotutils
from neurosynth.base import imageutils, mask
import numpy as np
import nipype.interfaces.fsl as fsl
import nibabel as nib


#######################
#BV  

# 1) Convert from Tal to MNI - Matlab
dat = fmri_data('/Users/lukechang/Research/Trust_Friend/Analyses/NeurosynthDecode/FriendWin_minusAll_05_uncorrected.nii');
t = dlmread('/Users/lukechang/Dropbox/Github/toolbox/Python/ImageProcessing/tal2icbm_fsl.mat');
dat.volInfo.mat = inv(t)*dat.volInfo.mat;
dat.fullpath = '/Users/lukechang/Research/Trust_Friend/Analyses/NeurosynthDecode/Friend.nii';
write(dat)

# 2) Reorient using FSL - Unix
fslreorient2std Friend Friend_Or

# 3) Coregister to 2mm MNI space - Unix
/usr/local/fsl/bin/flirt -in /Users/lukechang/Research/Trust_Friend/Analyses/NeurosynthDecode/Friend_Or.nii.gz -ref /usr/local/fsl/data/standard/MNI152_T1_2mm_brain -out /Users/lukechang/Research/Trust_Friend/Analyses/NeurosynthDecode/Friend_Or_Mni.nii.gz -omat /Users/lukechang/Research/Trust_Friend/Analyses/NeurosynthDecode/Friend_Or_Mni.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear

# 4) Decode - Python
DATASET_FILE = '/Users/lukechang/Dropbox/Github/neurosynth/topics.pkl'
PREFIX = '/Users/lukechang/Research/Trust_Friend/Analyses/NeurosynthDecode/'
INFILE = 'Friend_Or_Mni.nii.gz'
dataset = Dataset.load(DATASET_FILE)
decoder = decode.Decoder(dataset) #takes awhile to load, should only do this once.
img = imageutils.load_imgs(PREFIX + INFILE, decoder.mask)
result = decoder.decode(img)
np.savetxt(PREFIX + 'Friend_Decoded.txt', result)

# 5) Threshold at .001 - unix
fslmaths Friend_Or_Mni -thr 3 Friend_Or_Mni_001

# 6) Decode thresholded map - python
DATASET_FILE = '/Users/lukechang/Dropbox/Github/neurosynth/topics.pkl'
PREFIX = '/Users/lukechang/Research/Trust_Friend/Analyses/NeurosynthDecode/'
INFILE = 'Friend_Or_Mni_001.nii.gz'
dataset = Dataset.load(DATASET_FILE)
decoder = decode.Decoder(dataset) #takes awhile to load, should only do this once.
img = imageutils.load_imgs(PREFIX + INFILE, decoder.mask)
result = decoder.decode(img)
np.savetxt(PREFIX + 'Friend_001_Decoded.txt', result)




