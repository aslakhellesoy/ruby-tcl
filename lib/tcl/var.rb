module Tcl
  class Var
    include InterpHelper
    
    class << self
      def find(interp, name)
        StringVar.new(interp, name)
      rescue Tcl::Error => e
        if e.message["variable is array"]
          ArrayVar.new(interp, name)
        else
          raise
        end
      end
    end
    
    attr_reader :name
    
    def initialize(interp, name)
      @interp = interp
      @name = name.to_s
      to_tcl
    end
  end
  
  class StringVar < Var
    def value
      _!(:set, name)
    end
    
    def to_tcl
      _(:set, name, value)
    end
  end
  
  class ArrayVar < Var
    def value
      _!(:array, :get, name)
    end
    
    def to_tcl
      _(:array, :set, name, value)
    end
  end
end
