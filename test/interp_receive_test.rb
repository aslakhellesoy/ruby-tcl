require File.join(File.dirname(__FILE__), "test_helper")

class InterpWithNoReceiveMethod < Tcl::Interp
  undef_method :interp_receive
end

class InterpWithDefaultReceiveMethod < Tcl::Interp
  def tcl_no_arguments
    "hello"
  end
  
  def tcl_one_argument(arg)
    arg
  end
  
  def tcl_variable_arguments(*args)
    _(*args)
  end
  
  def tcl_multiply_by_5(n)
    n.to_i * 5
  end
end

class InterpWithCustomReceiveMethod < Tcl::Interp
  def interp_receive(method, *args)
    _(method, *args)
  end
end

class InterpWithExposedMethods < Tcl::Interp
  def initialize
    super
    expose :hello
  end
  
  def tcl_hello(who)
    "hello, #{who}"
  end
end

class InterpWithExitMethod < Tcl::Interp  
  def tcl_exit
    exit
  end
end

class InterpReceiveTest < Test::Unit::TestCase
  def setup
    @interp = InterpWithDefaultReceiveMethod.new
  end
  
  def test_interp_send_on_interp_with_no_interp_receive_method_should_raise
    @interp = InterpWithDefaultReceiveMethod.new
    assert_raises(Tcl::Error) { @interp.eval("interp_send") }
  end
  
  def test_interp_send_with_no_arguments_should_raise
    assert_raises(Tcl::Error) { @interp.eval("interp_send") }
  end
  
  def test_interp_send_returns_tcl_ok
    assert_equal "0",           @interp.eval("catch {interp_send no_arguments}")
  end
  
  def test_interp_send_to_method_with_no_arguments
    assert_equal "hello",       @interp.eval("interp_send no_arguments")
    assert_raises(Tcl::Error) { @interp.eval("interp_send no_arguments foo") }
  end
  
  def test_interp_send_to_method_with_one_argument
    assert_raises(Tcl::Error) { @interp.eval("interp_send one_argument") }
    assert_equal "foo",         @interp.eval("interp_send one_argument foo")
    assert_raises(Tcl::Error) { @interp.eval("interp_send one_argument foo bar") }
  end

  def test_interp_send_to_method_with_variable_arguments
    assert_equal "",            @interp.eval("interp_send variable_arguments")
    assert_equal "foo",         @interp.eval("interp_send variable_arguments foo")
    assert_equal "foo bar",     @interp.eval("interp_send variable_arguments foo bar")
  end
  
  def test_interp_send_converts_non_string_results_to_string
    assert_equal "0",           @interp.eval("interp_send multiply_by_5 0")
    assert_equal "25",          @interp.eval("interp_send multiply_by_5 5")
  end
  
  def test_interp_send_with_custom_interp_receive_method
    @interp = InterpWithCustomReceiveMethod.new
    assert_raises(Tcl::Error) { @interp.eval("interp_send") }
    assert_equal "foo",         @interp.eval("interp_send foo")
    assert_equal "foo bar",     @interp.eval("interp_send foo bar")
  end
  
  def test_interp_expose
    @interp = InterpWithExposedMethods.new
    assert_equal "hello, Sam",  @interp.eval("interp_send hello Sam")
    assert_equal "hello, Sam",  @interp.eval("hello Sam")
  end
  
  def test_interp_send_does_not_convert_system_exit_into_tcl_error
    @interp = InterpWithExitMethod.new
    assert_raises(SystemExit) { @interp.eval("interp_send exit") }
  end
end

