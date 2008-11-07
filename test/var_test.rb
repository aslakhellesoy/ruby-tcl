require File.join(File.dirname(__FILE__), "test_helper")

class VarTest < Test::Unit::TestCase
  def setup
    @interp = Tcl::Interp.load_from_file(path_to_fixture("test.tcl"))
  end
  
  def test_var_find_raises_when_var_does_not_exist
    assert_raises(Tcl::Error) { Tcl::Var.find(@interp, "nonexistent") }
  end
  
  def test_var_find_returns_string_var
    var = Tcl::Var.find(@interp, "a")
    assert_equal "a", var.name
    assert var.is_a?(Tcl::StringVar)
  end
  
  def test_var_find_returns_array_var
    var = Tcl::Var.find(@interp, "b")
    assert_equal "b", var.name
    assert var.is_a?(Tcl::ArrayVar)
  end
  
  def test_string_var_value
    assert_equal "0", @interp.var("a").value
  end
  
  def test_array_var_value
    assert_equal "a 1 b 2", @interp.var("b").value
  end
  
  def test_string_var_to_tcl
    assert_equal "set a 0", @interp.var("a").to_tcl
  end
  
  def test_array_var_to_tcl
    assert_equal "array set b {a 1 b 2}", @interp.var("b").to_tcl
  end
  
  def test_array_var_to_tcl_does_not_modify_errorInfo
    assert_errorinfo ""
    Tcl::Var.find(@interp, "b")
    assert_errorinfo ""
  end
  
  def test_attempting_to_find_nonexistent_variable_does_not_modify_errorInfo
    assert_errorinfo ""
    assert_raises(Tcl::Error) { Tcl::Var.find(@interp, "nonexistent") }
    assert_errorinfo ""
  end
  
  protected
    def assert_errorinfo(value)
      assert_equal value, @interp.var("errorInfo").value
    end
end
