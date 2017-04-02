module RayyanFormats
  class Target

    def method_missing(method_sym, *arguments, &block)
      # if method name is in the form x= then set dict[:x] to first argument value
      # otherwise, return dict[:x] if any
      method_sym.to_s =~ /(.+)=/
      if $1
        @dict[$1.to_sym] = arguments.first
      else
        @dict[method_sym]
      end
    end

    def initialize
      @dict = {}
    end

  end
end