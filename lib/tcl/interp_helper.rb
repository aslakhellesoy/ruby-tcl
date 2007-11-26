module Tcl
  module InterpHelper
    def self.included(klass)
      klass.class_eval do
        attr_reader :interp
      end
    end
    
    def _(*args)
      interp.array_to_list(args)
    end
    
    def _!(*args)
      interp.eval(_(*args))
    end
    
    def method_missing(name, *args, &block)
      if interp.respond_to?(name)
        interp.send(name, *args, &block)
      else
        super
      end
    end
  end
end
