module RayyanFormats
  class Source
    attr_accessor :name
    # name should be file name string ending with '.' then extension
    attr_accessor :attachment
    # attachment should be Ruby IO (responds to :size, :read and :close)
    # if not specified, File.open(:name) is performed to get contents

    def initialize(_name, _attachment = nil)
      self.name = _name
      self.attachment = _attachment.nil? ? File.open(_name) : _attachment
    end
  end
end