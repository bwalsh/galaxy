#!/bin/sh

PYTHON_2_7_PATH=/opt/python-2.7/
export http_proxy=http://sparkdmz1:4000
export https_proxy=${http_proxy}
export ftp_proxy=${http_proxy}
export GALAXY_RUN_ALL=1
#Creating env variables for location of exe/jar files, to be used by xml/py files.
GENOMICS_DIR=/opt/Genomics
export BWA_DIR=$GENOMICS_DIR/ohsu/dnapipeline/bwa-0.7.4
export BWA_EXE_PATH=$BWA_DIR/bwa
export SAMTOOLS_DIR=$GENOMICS_DIR/ohsu/dnapipeline/samtools-0.1.19
export SAMTOOLS_EXE_PATH=$SAMTOOLS_DIR/samtools
export PICARD_PATH=$GENOMICS_DIR/ohsu/dnapipeline/picard-tools-1.110
export GATK_JAR_PATH=/opt/gsa-unstable/target/GenomeAnalysisTK.jar
export CP_PATH=/cluster_share/cp_pipeline
export SEATTLESEQ_GETANNOTATION_JAR_PATH=/opt/Genomics/annotation/getAnnotation/project/
export SEATTLESEQ_WRITEGENOTYPE_JAR_PATH=/opt/Genomics/annotation/writeGenotype/project/
export MUTECT_JAR_PATH=$GENOMICS_DIR/ohsu/dnapipeline/mutect-1.1.7.jar
export PATH=$GENOMICS_DIR:$BWA_DIR:$SAMTOOLS_DIR:$PICARD_PATH:$PYTHON_2_7_PATH/bin:$PATH
export NSLOTS=16
export PYTHON_EGG_CACHE=.eggs_cache

cd `dirname $0`

# If there is a .venv/ directory, assume it contains a virtualenv that we
# should run this instance in.
if [ -d .venv ];
then
    printf "Activating virtualenv at %s/.venv\n" $(pwd)
    . .venv/bin/activate
fi

# If there is a file that defines a shell environment specific to this
# instance of Galaxy, source the file.
if [ -z "$GALAXY_LOCAL_ENV_FILE" ];
then
    GALAXY_LOCAL_ENV_FILE='./config/local_env.sh'
fi

if [ -f $GALAXY_LOCAL_ENV_FILE ];
then
    . $GALAXY_LOCAL_ENV_FILE
fi

python ./scripts/check_python.py
[ $? -ne 0 ] && exit 1

./scripts/common_startup.sh

if [ -n "$GALAXY_UNIVERSE_CONFIG_DIR" ]; then
    python ./scripts/build_universe_config.py "$GALAXY_UNIVERSE_CONFIG_DIR"
fi

if [ -z "$GALAXY_CONFIG_FILE" ]; then
    if [ -f universe_wsgi.ini ]; then
        GALAXY_CONFIG_FILE=universe_wsgi.ini
    elif [ -f config/galaxy.ini ]; then
        GALAXY_CONFIG_FILE=config/galaxy.ini
    else
        GALAXY_CONFIG_FILE=config/galaxy.ini.sample
    fi
    export GALAXY_CONFIG_FILE
fi

if [ -n "$GALAXY_RUN_ALL" ]; then
    servers=`sed -n 's/^\[server:\(.*\)\]/\1/  p' $GALAXY_CONFIG_FILE | xargs echo`
    echo "$@" | grep -q 'daemon\|restart'
    if [ $? -ne 0 ]; then
        echo 'ERROR: $GALAXY_RUN_ALL cannot be used without the `--daemon`, `--stop-daemon` or `restart` arguments to run.sh'
        exit 1
    fi
    (echo "$@" | grep -q -e '--daemon\|restart') && (echo "$@" | grep -q -e '--wait')
    WAIT=$?
    ARGS=`echo "$@" | sed 's/--wait//'`
    for server in $servers; do
        if [ $WAIT -eq 0 ]; then
            python ./scripts/paster.py serve $GALAXY_CONFIG_FILE --server-name=$server --pid-file=$server.pid --log-file=$server.log $ARGS
            while true; do
                sleep 1
                printf "."
                # Grab the current pid from the pid file
                if ! current_pid_in_file=$(cat $server.pid); then
                    echo "A Galaxy process died, interrupting" >&2
                    exit 1
                fi
                # Search for all pids in the logs and tail for the last one
                latest_pid=`egrep '^Starting server in PID [0-9]+\.$' $server.log -o | sed 's/Starting server in PID //g;s/\.$//g' | tail -n 1`
                # If they're equivalent, then the current pid file agrees with our logs
                # and we've succesfully started
                [ -n "$latest_pid" ] && [ $latest_pid -eq $current_pid_in_file ] && break
            done
            echo
        else
            echo "Handling $server with log file $server.log..."
            python ./scripts/paster.py serve $GALAXY_CONFIG_FILE --server-name=$server --pid-file=$server.pid --log-file=$server.log $@
        fi
    done
else
    # Handle only 1 server, whose name can be specified with --server-name parameter (defaults to "main")
    python ./scripts/paster.py serve $GALAXY_CONFIG_FILE $@
fi
