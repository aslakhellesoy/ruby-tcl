require File.join(File.dirname(__FILE__), "test_helper")

class ProcTest < Test::Unit::TestCase
  def setup
    @interp = Tcl::Interp.load_from_file(path_to_fixture("test.tcl"))
  end
  
  def test_proc_arguments_for_proc_with_no_arguments
    assert_equal [], @interp.proc("e").arguments
  end
  
  def test_proc_arguments_for_proc_with_one_argument
    assert_equal ["args"], @interp.proc("c").arguments
  end

  def test_proc_arguments_for_proc_with_default_argument
    assert_equal ["a", "b 0"], @interp.proc("d").arguments
  end
  
  def test_proc_body
    assert_equal "return",    @interp.proc("c").body
    assert_equal "return $b", @interp.proc("d").body
    assert_equal "",          @interp.proc("e").body
  end

  def test_proc_call
    assert_equal "",  @interp.proc("c").call
    assert_equal "0", @interp.proc("d").call("a")
    assert_equal "b", @interp.proc("d").call("a", "b")
    assert_equal "",  @interp.proc("e").call
  end
  
  def test_proc_call_raises_on_missing_argument
    assert_raises(Tcl::Error) { @interp.proc("d").call }
  end
  
  def test_proc_to_tcl
    assert_equal "proc c args return", @interp.proc("c").to_tcl
    assert_equal "proc d {a {b 0}} {return $b}", @interp.proc("d").to_tcl
    assert_equal "proc e {} {}", @interp.proc("e").to_tcl
  end
end
