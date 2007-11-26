module Tcl
  class Proc
    include InterpHelper

    attr_reader :name
    
    def initialize(interp, name)
      @interp = interp
      @name = name.to_s
      to_tcl
    end
    
    def arguments
      list_to_array(_!(:info, :args, name)).map do |argument_name|
        begin
          variable_name = "__Tcl_Proc_arguments_#{name}_#{argument_name}"
          if _!(:info, :default, name, argument_name, variable_name) == "0"
            argument_name
          else
            _(argument_name, var(variable_name).value)
          end
        ensure
          _!(:unset, variable_name)
        end
      end
    end
    
    def body
      _!(:info, :body, name)
    end
    
    def call(*args)
      _!(name, *args.map { |arg| arg.to_s })
    end
    
    def to_tcl
      _(:proc, name, _(*arguments), body)
    end
  end
end
