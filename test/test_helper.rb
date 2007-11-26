require "test/unit"
require File.join(File.dirname(__FILE__), *%w".. lib tcl")

class Tcl::Interp
  def clear!
    procs.each { |p| _! :rename, p, "" }
    vars.each  { |v| _! :unset, v }
  end
end

class Test::Unit::TestCase
  def path_to_fixture(*path_pieces)
    File.join(File.dirname(__FILE__), "fixtures", *path_pieces)
  end
end
