#!/bin/bash

#SET Argument variables
#HDFS_INPUT_PATH_FILE=/user/vijaym/adam/NA12878.bam
#HDFS_OUTPUT_PATH_FILE=/user/vijaym/adam/NA12878_CCC_TEST.adam
HDFS_INPUT_PATH_FILE=/user/vijaym/adam//NA12878.bam
HDFS_OUTPUT_PATH_FILE=/user/vijaym/adam//NA12878.adam
SEARCH='//'
HDFS_INPUT_PATH_FILE=${HDFS_INPUT_PATH_FILE/'//'/'/'}
HDFS_OUTPUT_PATH_FILE=${HDFS_OUTPUT_PATH_FILE/'//'/'/'}


#BEGIN Debugging the status of variables
NEW_LINE=`printf "\n\r"`
echo "===============START DEBUG===============" $NEW_LINE
echo "DATE & TIME:$(date +"%m-%d-%Y %T")" $NEW_LINE
echo "ADAM HOME:"$ADAM $NEW_LINE
echo "SPARK HOME:"$SPARK $NEW_LINE
echo "TESTING Yes/No:"$TEST $NEW_LINE
echo "ADAM SUBMIT:"$ADAM_SUBMIT $NEW_LINE
echo "HDFS_INPUT_PATH:"$HDFS_INPUT_PATH_FILE $NEW_LINE
echo "HDFS_OUTPUT_PATH:"$HDFS_OUTPUT_PATH_FILE $NEW_LINE
echo "===============END DEBUG===============" $NEW_LINE
#END Debugging the status of variables

####################################################################################################
# This function checks for success failure errors and captures the errors into the log file
# It accepts two parameters. 
#    Parm1:  always $? becuase the last command executed needs to be captured
#    Parm2:  string. sucess message
#    Parm3:  string. stderror message unsucessful message
#    Parm4:  0 or non 0 integer. if 0 the program exits if not it continues
# Author: Vijay Ranjan mungara
# Version: 1.0   5/8/2013
# Eample usage: iferr=$(ls $1 2>&1) 
#               fnc_check_error $? "ls was successful" "$iferr" 0
####################################################################################################
fnc_check_error() {
ret_cd=$1
NEWER_LINE=`printf "\n\r"`
if [ $ret_cd -ne 0 ]; then
   echo `date` "$NEWER_LINE:-EXECUTION-FAILED-WITH-RETURN-CODE:-'$ret_cd': AND-WITH-FAILURE-MESSAGE: $NEWER_LINE$3"
   if [ $4 -eq 0 ]; then
	exit $ret_cd
   fi
else
   echo `date` "$NEWER_LINE:-Execution succeeded with return code 0.: With Success Message: $NEWER_LINE$2"
fi
}

#TESTING TRUE / FALSE

TEST=false
if [ "$TEST" == "true" ]; then
	HADOOP_COMMAND=`/usr/bin/which hadoop`
	#RETURN=$($HADOOP_COMMAND fs -test $HDFS_OUTPUT_PATH_FILE)
	#if [ $RETURN == 0 ]; then
		echo "HADOOP_COMMAND:"$HADOOP_COMMAND $NEW_LINE
		echo "HADOOP_PATH:"$HADOOP_PATH $NEW_LINE
		iferr=$($HADOOP_COMMAND fs -rm -r $HDFS_OUTPUT_PATH_FILE 2>&1)
		fnc_check_error $? "DELETED the Ouput File so that the test succeeds" "$iferr" 1
	#fi
fi

#CALL to Adam
iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client transform $HDFS_INPUT_PATH_FILE $HDFS_OUTPUT_PATH_FILE  2>&1)
fnc_check_error $? "*** Adam Transform from BAM file to ADAM file Succeeded ***" "$iferr" 0
