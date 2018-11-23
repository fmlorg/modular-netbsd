#
# $Id$
# $FML$
#


logit () {
    local msg="$*"
    local name=$(basename $0)

    if [ -w $logf ];then
	echo   "${name}: $msg" >> $logf
    fi
    logger -t $name "$msg"
}


fatal () {
    logit "***fatal: $*"
    exit 1
}


debug_msg () {
    echo "===> DEBUG: $*" 1>&2    
}


random_number () {
    echo $(od -An -N 2 -t u2 /dev/urandom)
}


# XXX NOT-POSIX
unixtime () {
    echo $(date +%s)
}


run_hook () {
    local hook=$1

    if [ -f $hook ];then
	logit "run_hook: run $hook"
	(
	    . $hook
	)
        if [ $? != 0 ];then
	    fatal "run_hook: failed: $hook"
        fi
    fi
}
