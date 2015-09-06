#! /bin/bash

unset LD_LIBRARY_PATH
ruby /opt/splunk/bin/scripts/ssl2notice.rb $@
