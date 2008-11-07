module Tcl
  class Var
    BUILTINS = %w(
      auto_index auto_oldpath auto_path env errorCode errorInfo
      tcl_libPath tcl_library tcl_patchLevel tcl_pkgPath tcl_platform tcl_version
    )
    
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
    
    def builtin?
      BUILTINS.include?(name)
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
