#!/usr/bin/env python
#Adapted from Dan Blankenberg

"""
A wrapper script for running the SeattleSeq writeGenotype jarfile
"""

import sys, optparse, os, tempfile, subprocess, shutil

CHUNK_SIZE = 2**20 #1mb

def cleanup_before_exit( tmp_dir ):
    if tmp_dir and os.path.exists( tmp_dir ):
        shutil.rmtree( tmp_dir )

def open_file_from_option( filename, mode = 'rb' ):
    if filename:
        return open( filename, mode = mode )
    return None

def __main__():
    #Parse Command Line
    #   TODO:  the short option IDs should be cleaned up
    parser = optparse.OptionParser()
    parser.add_option( '-p', '--pass_through', dest='pass_through_options', action='store', type="string", help='These options are passed through directly to the getAnnotation jarfile, without any modification.' )
    parser.add_option( '-v', '--input_vcf', dest='input_vcf', action='store', type="string", default=None, help='VCF generated from GATK PrintReads')
    parser.add_option( '-a', '--input_getAnnotation', dest='input_getAnnotation', action='store', type="string", default=None, help='Text file generated by SeattleSeq getAnnotation')
    parser.add_option( '-c', '--input_coverage', dest='input_coverage', action='store', type="string", default=None, help='Text file generated by GATK DepthOfCoverage tool')
    parser.add_option( '-o', '--output', dest='output', action='store', type="string", default=None, help='Output file')
    parser.add_option( '-d', '--database_info', dest='input_database_info', action='store', type="string", default=None, help='Login information for GVS and HGMD databases')
    parser.add_option( '-g', '--input_actionableCarrierGenes', dest='input_actionableCarrierGenes', action='store', type="string", default=None, help='Text file containing list of actionable carrier genes')
    parser.add_option( '-i', '--input_incidentalGenes', dest='input_incidentalGenes', action='store', type="string", default=None, help='Text file containing list of incidental genes')
    parser.add_option( '-r', '--input_pharmGenes', dest='input_pharmGenes', action='store', type="string", default=None, help='Text file containing list of pharmacological genes')
    parser.add_option( '-b', '--input_SIFTBins', dest='input_SIFTBins', action='store', type="string", default=None, help='Text file containing SIFT bins')

    parser.add_option( '', '--stdout', dest='stdout', action='store', type="string", default=None, help='If specified, the output of stdout will be written to this file.' )
    parser.add_option( '', '--stderr', dest='stderr', action='store', type="string", default=None, help='If specified, the output of stderr will be written to this file.' )

    (options, args) = parser.parse_args()
 
    #   This is a workaround.  The output destination file ane path passed through to this script from Galaxy has a .dat extension.
    #       The output of this jarfile has a .xls file extension.  Galaxy will not recognize the jarfile output with such an 
    #       extension.  So we write the jarfile's .xls file to a temporary directory, then at the end of this script, move the
    #       file from the temporary directory to the path and filename (with .dat extension) that Galaxy expects
    #   The move is performed at the end of this __main__ function; see below for further detail
    tmp_dir = tempfile.mkdtemp( prefix='tmp-writeGenotype-' )
    tmp_output = tempfile.NamedTemporaryFile( dir=tmp_dir )
    tmp_output_name = tmp_output.name
    
    if options.pass_through_options:
        cmd = ' '.join( options.pass_through_options )
    else:
        cmd = ''
    
    assert None not in [ options.pass_through_options,  \
        options.input_vcf, \
        options.input_getAnnotation, \
        options.input_coverage, \
        options.output, \
        options.input_database_info,  \
        options.input_actionableCarrierGenes,   \
        options.input_incidentalGenes,  \
        options.input_pharmGenes,
        options.input_SIFTBins], 'Missing parameter(s)'
    print "Pass-through options:"
    print options.pass_through_options
    print "Input vcf:"
    print options.input_vcf
    print "Input getAnnotation:"
    print options.input_getAnnotation
    print "Input coverage:"
    print options.input_coverage
    print "Output:"
    print options.output
    print "Temporary output:"
    print tmp_output_name
    print "Input databaseInfo:"
    print options.input_database_info
    print "Input actionableCarrierGenes:"
    print options.input_actionableCarrierGenes
    print "Input incidentalGenes:"
    print options.input_incidentalGenes
    print "Input pharmGenes:"
    print options.input_pharmGenes
    print "Input SIFTBins:"
    print options.input_SIFTBins

    #   Note that tmp_output_name is our temporary file:  see above and below for details
    cmd = '%s %s %s %s %s %s %s %s %s %s' % ( options.pass_through_options, \
        options.input_vcf, \
        options.input_getAnnotation, \
        options.input_coverage, \
        tmp_output_name, \
        options.input_database_info, \
        options.input_actionableCarrierGenes, \
        options.input_incidentalGenes, \
        options.input_pharmGenes,
        options.input_SIFTBins)
    print "Command:"
    print cmd
    
    #set up stdout and stderr output options
    stdout = open_file_from_option( options.stdout, mode = 'wb' )
    if stdout is None:
        stdout = sys.stdout
    stderr = open_file_from_option( options.stderr, mode = 'wb' )
    #if no stderr file is specified, we'll use our own
    if stderr is None:
        stderr = tempfile.NamedTemporaryFile( prefix="writeGenotype-stderr-", dir=tmp_dir )

    #   Execute command and check for errors
    proc = subprocess.Popen( args=cmd, stdout=stdout, stderr=stderr, shell=True, cwd=tmp_dir )
    return_code = proc.wait()

    if return_code:
        stderr_target = sys.stderr
    else:
        stderr_target = sys.stdout
    stderr.flush()
    stderr.seek(0)
    while True:
        chunk = stderr.read( CHUNK_SIZE )
        if chunk:
            stderr_target.write( chunk )
        else:
            break
    stderr.close()

    #   Move the temporary output to the location Galaxy expects
    #       This is part of a workaround forced by Galaxy's difficulty handling .xls files
    #       See above for additional details
    tmp_output.close()
    tmp_output_name_final = '%s.xls' % tmp_output_name
    shutil.move( tmp_output_name_final, options.output)

    cleanup_before_exit( tmp_dir )

if __name__=="__main__": __main__()



