$:.unshift File.dirname(__FILE__)

require File.join(File.dirname(__FILE__), *%w".. src tcl")
require "tcl/interp_helper"
require "tcl/interp"
require "tcl/proc"
require "tcl/var"
