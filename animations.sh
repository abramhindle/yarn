#!/usr/bin/sh
perl animator.pl -Cd -o postgresql.default.swf
perl animator.pl -Ci -o postgresql.important.swf
perl animator.pl -Chd -o postgresql.highlight_decay.swf -decay 4
perl animator.pl -Cid -o postgresql.important_decay.swf -decay 4
perl animator.pl -Cdd -o postgresql.everything_colorful_decay.swf -decay 4
