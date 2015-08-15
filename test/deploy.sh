#! /bin/bash

DIR_TD_PLUGIN=/opt/td-agent/embedded/lib/ruby/gems/2.1.0/gems/fluentd-0.12.12/lib/fluent/plugin/
DIR_TD_CONF=/etc/td-agent/plugin/

DIR_TD_GEMS=/opt/td-agent/embedded/lib/ruby/2.1.0/

cp -f ../plugin/out_mon_df.rb $DIR_TD_PLUGIN
cp -f ../etc/mon_intel_df.conf $DIR_TD_CONF

cp -f ../lib/eapier.rb $DIR_TD_GEMS
