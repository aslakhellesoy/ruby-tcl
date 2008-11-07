require File.join(File.dirname(__FILE__), "test_helper")

class InterpTest < Test::Unit::TestCase
  def setup
    @interp = Tcl::Interp.new
  end
  
  def test_load_from_file
    vars, procs = @interp.vars, @interp.procs
    @interp = Tcl::Interp.load_from_file(path_to_fixture("test.tcl"))

    assert_equal ["a", "b"],       (@interp.vars - vars).sort
    assert_equal ["c", "d", "e"],  (@interp.procs - procs).sort
  end
  
  def test_eval
    assert_equal "",                @interp.eval("")
    assert_equal "0",               @interp.eval("return 0")
    assert_equal "",                @interp.eval("return \"\"")
    assert_equal "",                @interp.eval("return {}")
    assert_equal " ",               @interp.eval("return \" \"")
  end
  
  def test_eval_raises_on_tcl_exception
    assert_raises(Tcl::Error)     { @interp.eval("nonexistent") }
    assert_raises(Tcl::Error)     { @interp.eval("{") }
    assert_raises(Tcl::Error)     { @interp.eval("error") }
  end
  
  def test_eval_with_timeout_argument
    if defined?(Tcl::Timeout)
      assert_raises(Tcl::Timeout) { @interp.eval("while 1 {}", 100) }
    end
  end
  
  def test_array_to_list
    assert_equal "",                @interp.array_to_list([])
    assert_equal "{}",              @interp.array_to_list([nil])
    assert_equal "{}",              @interp.array_to_list([""])
    assert_equal "one",             @interp.array_to_list(["one"])
    assert_equal "one two",         @interp.array_to_list(["one", "two"])
    assert_equal "a { b} c",        @interp.array_to_list(["a", " b", "c"])
    assert_equal "\\{",             @interp.array_to_list(["{"])
    assert_equal "{\"}",            @interp.array_to_list(["\""])
  end
  
  def test_list_to_array
    assert_equal [],                @interp.list_to_array("")
    assert_equal [""],              @interp.list_to_array("{}")
    assert_equal ["one"],           @interp.list_to_array("one")
    assert_equal ["one", "two"],    @interp.list_to_array("one two")
    assert_equal ["a", " b", "c"],  @interp.list_to_array("a { b} c")
    assert_equal ["a", " b", "c"],  @interp.list_to_array("a \\ b c")
    assert_equal ["{"],             @interp.list_to_array("\\{")
    assert_equal ["["],             @interp.list_to_array("\\[")
    assert_equal ["\""],            @interp.list_to_array("\\\"")
  end
  
  def test_procs
    @interp.clear!
    assert_equal [], @interp.procs
    @interp.eval "proc foo {} {}"
    assert_equal ["foo"], @interp.procs
    @interp.eval "proc bar {} {}"
    assert_equal ["bar", "foo"], @interp.procs.sort
  end
  
  def test_vars
    @interp.clear!
    assert_equal [], @interp.vars
    @interp.eval "set a 0"
    assert_equal ["a"], @interp.vars
    @interp.eval "set b(a) 0"
    assert_equal ["a", "b"], @interp.vars.sort
  end
  
  def test_proc
    assert_raises(Tcl::Error) { @interp.proc("foo") }
    @interp.eval "proc foo {} {}"
    proc = @interp.proc("foo")
    assert proc.is_a?(Tcl::Proc)
    assert_equal "foo", proc.name
  end
  
  def test_var
    assert_raises(Tcl::Error) { @interp.var("foo") }
    @interp.eval "set foo bar"
    var = @interp.var("foo")
    assert var.is_a?(Tcl::Var)
    assert_equal "foo", var.name
  end
  
  def test_to_tcl
    @interp.eval IO.read(path_to_fixture("test.tcl"))
    assert_equal <<-EOF.chomp, @interp.to_tcl
set a 0
array set b {a 1 b 2}
proc c args return
proc d {a {b 0}} {return $b}
proc e {} {}
    EOF
  end
  
  def test_interp_helper_method_missing_super_passthrough
    assert_raises(NoMethodError) { @interp.nonexistent }
  end
end
