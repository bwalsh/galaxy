#!/bin/bash

#SET Argument variables
#HDFS_INPUT_PATH_FILE=/user/vijaym/adam/NA12878.bam
#HDFS_OUTPUT_PATH_FILE=/user/vijaym/adam/NA12878_CCC_TEST.adam
HDFS_INPUT_PATH_FILE=/user/vijaym/adam//NA12878.bam

HDFS_ADAM_PATH_FILE=/user/vijaym/adam//NA12879.adam
HDFS_VCF_PATH_FILE=/user/vijaym/adam//dbsnp_132.vcf
HDFS_VAR_PATH_FILE=/user/vijaym/adam//dbsnp_133.var.adam
HDFS_MKDUP_PATH_FILE=/user/vijaym/adam//NA12879.mkdup.adam
HDFS_SORT_PATH_FILE=/user/vijaym/adam//NA12879.sort.adam
HDFS_RI_PATH_FILE=/user/vijaym/adam//NA12879.ri.adam
HDFS_BQSR_PATH_FILE=/user/vijaym/adam//NA12879.bqsr.adam

SEARCH='//'
HDFS_INPUT_PATH_FILE=${HDFS_INPUT_PATH_FILE/'//'/'/'}
HDFS_ADAM_PATH_FILE=${HDFS_ADAM_PATH_FILE/'//'/'/'}
HDFS_VCF_PATH_FILE=${HDFS_VCF_PATH_FILE/'//'/'/'}
HDFS_VAR_PATH_FILE=${HDFS_VAR_PATH_FILE/'//'/'/'}
HDFS_MKDUP_PATH_FILE=${HDFS_MKDUP_PATH_FILE/'//'/'/'}
HDFS_SORT_PATH_FILE=${HDFS_SORT_PATH_FILE/'//'/'/'}
HDFS_RI_PATH_FILE=${HDFS_RI_PATH_FILE/'//'/'/'}
HDFS_BQSR_PATH_FILE=${HDFS_BQSR_PATH_FILE/'//'/'/'}

#BEGIN Debugging the status of variables
NEW_LINE=`printf "\n\r"`
echo "===============START DEBUG===============" $NEW_LINE
echo "START DATE & TIME:$(date +"%m-%d-%Y %T")" $NEW_LINE
echo "HDFS_INPUT_PATH:"$HDFS_INPUT_PATH_FILE $NEW_LINE
echo "HDFS_OUTPUT_PATH:"$HDFS_OUTPUT_PATH_FILE $NEW_LINE
#END Debugging the status of variables

#--executor-cores 24 --executor-memory 125g
# --conf spark.shuffle.service.enable=true --master spark://g1.spark0.intel.com:7077 
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
   echo `date` ":-EXECUTION-FAILED-WITH-RETURN-CODE:-'$ret_cd': AND-WITH-FAILURE-MESSAGE: $NEWER_LINE$3"
   if [ $4 -eq 0 ]; then
	exit $ret_cd
   fi
else
   echo `date` ":-Execution succeeded With: $2"
fi
}

#hadoop fs -rm -r $HDFS_OUTPUT_PATH_FILE
iferr=$(hadoop fs -rm -r $HDFS_ADAM_PATH_FILE 2>&1)
iferr=$(hadoop fs -rm -r $HDFS_VAR_PATH_FILE 2>&1)
iferr=$(hadoop fs -rm -r $HDFS_MKDUP_PATH_FILE 2>&1)
iferr=$(hadoop fs -rm -r $HDFS_SORT_PATH_FILE 2>&1)
iferr=$(hadoop fs -rm -r $HDFS_RI_PATH_FILE 2>&1)
iferr=$(hadoop fs -rm -r $HDFS_BQSR_PATH_FILE 2>&1)
fnc_check_error $? "DELETED the Ouput File In case it exists" "$iferr" 1

iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client transform $HDFS_INPUT_PATH_FILE $HDFS_ADAM_PATH_FILE 2>&1)
fnc_check_error $? "Transform Bam to Adam Function Succeeded on Hadoop/Spark/Adam" "$iferr" 0

iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client flagstat $HDFS_ADAM_PATH_FILE 2>&1)
fnc_check_error $? "Flagstat Function Succeeded on Hadoop/Spark/Adam" "$iferr" 0

iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client transform $HDFS_ADAM_PATH_FILE $HDFS_SORT_PATH_FILE  -sort_reads 2>&1)
fnc_check_error $? "Transform Sorting Function Succeeded on Hadoop/Spark/Adam" "$iferr" 0

iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client transform $HDFS_SORT_PATH_FILE $HDFS_MKDUP_PATH_FILE  -mark_duplicate_reads 2>&1)
fnc_check_error $? "Transform Marking Duplicates Function Succeeded on Hadoop/Spark/Adam" "$iferr" 0

iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client vcf2adam $HDFS_VCF_PATH_FILE $HDFS_VAR_PATH_FILE -onlyvariants 2>&1)
fnc_check_error $? "*** Coverting VCF to Adam / converting known snps file to adam variants file succeeded ***" "$iferr" 0

iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client transform $HDFS_MKDUP_PATH_FILE $HDFS_BQSR_PATH_FILE -recalibrate_base_qualities -known_snps $HDFS_VAR_PATH_FILE 2>&1)
fnc_check_error $? "Recalibrating Base Qualities Function Succeeded on Hadoop/Spark/Adam" "$iferr" 0

iferr=$(export SPARK_HOME=/opt/cloudera/parcels/CDH-5.4.4-1.cdh5.4.4.p0.4/lib/spark; /opt/adam/adam-distribution-0.16.0/bin/adam-submit --conf spark.shuffle.service.enable=true --master yarn-client transform $HDFS_BQSR_PATH_FILE $HDFS_RI_PATH_FILE -realign_indels 2>&1)
fnc_check_error $? "Transform Realigning Indels Function Succeeded on Hadoop/Spark/Adam" "$iferr" 0

echo "END DATE & TIME:$(date +"%m-%d-%Y %T")" $NEW_LINE
echo "===============END DEBUG==============="