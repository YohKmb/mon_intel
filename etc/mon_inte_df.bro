# Put this configuration file into site-specific config directory.
#  ex. $PREFIX/share/bro/site
#
# Then added statement like `@load mon_intel_df` to local.bro and so on.
#

@load intel

@load policy/frameworks/intel/seen
@load policy/frameworks/intel/do_notice

redef Intel::read_files += {
        "/opt/bro/feeds/mayhemic.intel"
};

