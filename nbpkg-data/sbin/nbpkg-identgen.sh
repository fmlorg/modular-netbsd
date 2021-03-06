#!/bin/sh
#
# Copyright (C) 2018 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under 2-Clause BSD License.
#   https://opensource.org/licenses/BSD-2-Clause
#
# mailto: fukachan@fml.org
#    web: http://www.fml.org/
#
# $FML$
# $Revision$
#        NAME: nbpkg-identgen.sh
# DESCRIPTION: dump ident info for the specific NetBSD.
# CODINGSTYLE: POSIX compliant (checked by running "bash --posix" this script)
#

############################################################
####################   CONFIGURATIONS   ####################
############################################################

etc_dir=$(dirname $0)/../../nbpkg-build/etc
lib_dir=$(dirname $0)/../../nbpkg-build/lib
wrk_dir=$(dirname $0)/../../nbpkg-data/work

. $etc_dir/defaults/config.sh
. $etc_dir/config.sh

############################################################
####################      FUNCTIONS     ####################
############################################################

. $lib_dir/libutil.sh
. $lib_dir/libqueue.sh
. $lib_dir/libnbpkg.sh
. $lib_dir/libnbdist.sh

############################################################
####################        MAIN        ####################
############################################################

set -u

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

nbpkg_build_assert

# global flags
is_debug=${DEBUG:-""}
is_require_download_and_extract=""

# parse options
while getopts dvhb: _opt
do
    case $_opt in
       h | \?) echo "usage: $0 [-hdv] -b BRANCH [ARCH ...]" 1>&2; exit 1;;
       d | v)  is_debug=1;;
       b)      branch=$OPTARG;;
    esac
done
shift $(expr $OPTIND - 1)
list=${1:-}

# determine target arch to build
#    url_base = http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-8/
#  build_nyid = 201811180430Z
#  build_date = 20181118
  url_base=$(nbdist_get_url_base $branch)
build_nyid=$(nbdist_get_latest_entry $url_base)
build_date=$(echo $build_nyid | awk '{print substr($1, 0, 8)}')

# dummy build_date since NetBSD major release has no such $build_nyid.
build_date=${build_date:-19700101}

list_all=$(nbdist_get_list $url_base$build_nyid/			|
tee /tmp/debug	| 
		tr ' ' '\n'						|
		grep '^[a-z]'						)

for arch in ${list:-$list_all}
do
    is_ignore=$(nbdist_check_ignore $arch)
    if [ $is_ignore = 1 ];then continue;fi
    
    nbpkg_dir_init $arch $branch $build_date
    nbpkg_log_init $arch $branch $build_date
    (
	logit "session: start $arch $branch $build_nyid"
	t_start=$(unixtime)

	_dir=$wrk_dir/$branch
	_out=$_dir/$arch
	test -d $_dir || mkdir -p $_dir

	nbdist_download $arch $url_base$build_nyid/$arch/binary/sets/
	nbdist_extract  $arch
	nbdist_get_ident_list $arch $branch $build_date $_out

	t_end=$(unixtime)
	t_diff=$(($t_end - $t_start))
	logit "session: end $arch $branch $build_nyid total: $t_diff sec."
	exit 0
    )

    if [ $? != 0 ];then
	nbpkg_dir_clean 1
    	logit "session: ***error*** arch=$arch ended abnormally."
    else
	nbpkg_dir_clean 0
    fi

done

exit 0
