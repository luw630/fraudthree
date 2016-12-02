#!/bin/bash
#===============================================================================
#      FILENAME: publish.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, xiangkun@ximigame.com
#       COMPANY: XiMi Co.Ltd
#      REVISION: 2014-12-31 by leoxiang
#===============================================================================

function usage
{
  echo "./publish [name]"
  exit
}

PATH="$(dirname $0)/lbf/lbf:$PATH"
source lbf_init.sh

#[ "$1" = "" ] && usage

echo "please select which to pack: "
echo "0)  all-packs"
echo "1)  common only"
echo "2)  all project"

read -p "please select which to pack: " var_select_list
read -p "please input svr-conf kinds:"  var_svrconf_kinds

var_pack_list=""
var_common_path="../../common/"
var_luac_path="../../common/skynet/3rd/lua/luac"
var_tmp_path="../tmp"
if [ ! -d $var_tmp_path ]; then
  `mkdir $var_tmp_path`
fi
var_pwd=`pwd`
echo "Current Path:"$var_pwd
var_pro_tmp=`dirname $var_pwd`
trunk_dir=`basename $var_pwd`
project_dir=`basename $var_pro_tmp`
echo "Project:"$project_dir
echo "Trunk:"$trunk_dir
var_tmp_trunk=$var_tmp_path"/"$project_dir"/"$trunk_dir
if [ ! -d $var_tmp_trunk ]; then
  `mkdir -p $var_tmp_trunk`
fi


for _var_select in ${var_select_list}; do
  case ${_var_select} in
    0)  echo "pack common and $project_dir"
        echo "copy ../../common ...."
        `cp -r $var_common_path $var_tmp_path`
        echo "copy $project_dir/$trunk_dir ....."
        `rm -rf logs`
        `cp -r * $var_tmp_trunk`
        echo "compile lua-script............"
        Luas=`find ${var_tmp_path} -name *.lua`
        for line in ${Luas};
        do
            `$var_luac_path -o $line $line`
            echo "compile lua file: "$line"......"
        done
        ;;
    1)  echo "pack common only............."
        echo "copy ../../common ...."
        `cp -r $var_common_path $var_tmp_path`
        echo "compile lua-script............"
        Luas=`find ${var_tmp_path} -name *.lua`
        for line in ${Luas};
        do
            `$var_luac_path -o $line $line`
             echo "compile lua file: "$line"......"
        done
        ;;
    2)  echo "pack "${trunk_dir}" all-server"
        `rm -rf logs`
        `cp -r * $var_tmp_trunk`
        echo "compile lua-script............"
        Luas=`find ${var_tmp_path} -name *.lua`
        for line in ${Luas};
        do
           `$var_luac_path -o $line $line`
            echo "compile lua file: "$line"......"
        done
        ;;
    *)  echo "unknown tpye ${_var_select}"; exit 0;;
  esac
done

echo "================="
echo "delete privious files"
var_dir="../package"
if [ ! -d $var_dir ]; then
  `mkdir $var_dir`
fi
#svn up  ${var_dir} --accept theirs-full
#svn revert ${var_dir} -R
#svn del ${var_dir}/* --force
#
echo "===========change to tmp ========="$var_tmp_path"---"${project_dir}
cd ${var_tmp_path}

var_conf_path_form="${project_dir}/${trunk_dir}/config/svr_bak"
var_conf_path_to="${project_dir}/${trunk_dir}/config/svr"
conftmp=`find ${var_conf_path_form} -name *.${var_svrconf_kinds}`
for line in ${conftmp}
do
    confname=`basename ${line}`
    echo "copy conf : "${line}" to "${var_conf_path_to}"/"${confname%.*}
    cp ${line} ${var_conf_path_to}/${confname%.*}
done

svndir=`find ./ -name .svn`
`rm -rf $svndir`
gitdir=`find ./ -name .git`
`rm -rf $gitdir`
echo "================="
echo "begin pack"
var_file="${var_dir}/${project_dir}_${trunk_dir}_$(date '+%Y%m%d%H%M%S').zip"
zip -r ${var_file} common ${project_dir}

cd ${var_pwd}
#
#echo "================="
#echo "calc md5"
#echo http://insvn.ximigame.net/svn/serversvn/codebase/games/texas/package/$(basename ${var_file})
#md5sum ${var_file}
#
#echo "================="
#echo "upload svn"
#svn add ${var_file}
#svn ci  ${var_dir} -m "texas package ${var_file}"
#
## vim:ts=2:sw=2:et:
`rm -rf $var_tmp_path`
