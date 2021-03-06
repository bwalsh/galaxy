"""
Unit test utilities.
"""
import os
import sys
import textwrap


# =============================================================================
def get_unittest_utils_path():
    return os.path.normpath( os.path.join( os.getcwd(), os.path.dirname( __file__ ) ) )


def get_galaxy_root():
    # precondition: this file must be at <GALAXY_ROOT>/test/unit/unittest_utils/utility.py
    return os.path.normpath( os.path.join( get_unittest_utils_path(), '../../../' ) )


def get_galaxy_libpath():
    # precondition: this file must be at <GALAXY_ROOT>/test/unit/unittest_utils/utility.py
    return os.path.join( get_galaxy_root(), 'lib' )


def clean_multiline_string( multiline_string, sep='\n' ):
    """
    Dedent, split, remove first and last empty lines, rejoin.
    """
    multiline_string = textwrap.dedent( multiline_string )
    string_list = multiline_string.split( sep )
    if not string_list[0]:
        string_list = string_list[1:]
    if not string_list[-1]:
        string_list = string_list[:-1]
    # return '\n'.join( docstrings )
    return ''.join([ ( s + '\n' ) for s in string_list ])


# =============================================================================
sys.path.insert( 0, get_galaxy_libpath() )
sys.path.insert( 1, get_unittest_utils_path() )
