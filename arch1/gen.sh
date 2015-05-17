#!/bin/sh
#syscontain software.rsf software.syscon.rsf
#egrep "^contain" software.syscon.rsf  > syscontain
#echo > syscontain
cat contains  | fgrep -vf badcontain > safecontain 
#cat safecontain syscontain | sort | uniq   > totalcontain
addcontain safecontain software.rsf software.con.ta
#lift software.con.ta software.lift.ta 5
schema software.con.ta software.ls.ta

