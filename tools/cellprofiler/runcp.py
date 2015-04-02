import subprocess
import sys
import os

DEVNULL = open(os.devnull,'wb') #This is needed to supress ilastik error due to running CellProfiler in headless configuration
cp_path = os.environ['CP_PATH']
if(sys.argv > 3):
	print "Too many command line arguments"
if(sys.argv[1] == 'bcc'):
	os.chdir(cp_path+'/bcc/')
	subprocess.call('python createSymLinks.py',shell=True)
	subprocess.call('python createFileList.py',shell=True)
	subprocess.call('python makeHeadless.py',shell=True)
	subprocess.call('cellprofiler -c -p headless.cppipe -i '+cp_path+'/bcc/ -o '+cp_path+'/bcc/output --data-file imageList.csv',shell=True,stderr=DEVNULL)
	subprocess.call('python curateTSV.py '+sys.argv[2],shell=True)
	subprocess.call('rm headless.cppipe',shell=True)
	subprocess.call('python removeSymLinks.py',shell=True)
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
	System.out.println("Pipeline has not been implemented. Use Brenden Colson Center instead");

