require "mkmf"

# To build against Tcl 8.5 on OS X Intel:
# RC_ARCHS=i386 ruby extconf.rb --with-tcl-dir=/path/to/tcl8.5

dir_config("tcl")
have_library("tcl") unless have_library("tcl8.5")
create_makefile("tcl_ruby")
