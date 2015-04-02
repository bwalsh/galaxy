import subprocess
import sys
import os
from random import randint

DEVNULL = open(os.devnull,'wb') #This is needed to supress ilastik error due to running CellProfiler in headless configuration
cp_path = os.environ['CP_PATH']
outpath = str(randint(1,100000))
tmppath = cp_path + '/bcc/' + outpath 
if(sys.argv > 3):
	print "Too many command line arguments"
if(sys.argv[1] == 'bcc'):
	subprocess.call('mkdir '+tmppath,shell=True)
	subprocess.call('mkdir '+tmppath+'/output',shell=True)
	os.chdir(tmppath)
	subprocess.call('ln -s ../* '+tmppath, shell=True)
	subprocess.call('python createSymLinks.py',shell=True)
	subprocess.call('python createFileList.py',shell=True)
	subprocess.call('python makeHeadless.py',shell=True)
	subprocess.call('cellprofiler -c -p headless.cppipe -i '+cp_path+'/bcc/ -o '+tmppath+'/output --data-file imageList.csv',shell=True,stderr=DEVNULL)
	subprocess.call('python curateTSV.py '+sys.argv[2],shell=True)
	subprocess.call('rm headless.cppipe',shell=True)
	subprocess.call('python removeSymLinks.py',shell=True)
	os.chdir(cp_path + '/bcc/')
	subprocess.call('rm -rf '+outpath,shell=True)
elif(sys.argv[1] == 'corless'):#existing pipeline filters out images (regex needs to converted to LoadImages Module)
	os.chdir(cp_path + '/Corless_pipeline/')
	subprocess.call('python createSymLinks.py',shell=True)
	subprocess.call('python createFileList.py',shell=True)
	subprocess.call('python makeHeadless.py',shell=True)
	subprocess.call('cellprofiler -c -p headless.cppipe -i '+cp_path+ '/Corless_pipeline/ -o '+cp_path+'/Corless_pipeline/output --data-file imageList.csv',shell=True)
elif(sys.argv[1] == 'taka'):
	os.chdir(cp_path+'/Takahiro_Flow_Cytometry/')
	subprocess.call('python createSymLinks.py',shell=True)
	subprocess.call('python createFileList.py',shell=True)
	subprocess.call('python makeHeadless.py',shell=True)
	subprocess.call('cellprofiler -c -p headless.cppipe -i '+cp_path+'/Takahiro_Flow_Cytometry/ -o '+cp_path+'/Takahiro_Flow_Cytometry/output --data-file imageList.csv',shell=True)
else:
	print "Pipeline has not been implemented. Use Brenden Colson Center instead"
	exit(1)
