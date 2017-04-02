module RayyanFormats
  class Source
    attr_accessor :name
    # name should be file name string ending with '.' then extension
    attr_accessor :attachment
    # attachment should be Ruby IO (responds to :size, :read and :close)

    def initializer(_name, _attachment)
      self.name = _name
      self.attachment = _attachment
    end
  end
end