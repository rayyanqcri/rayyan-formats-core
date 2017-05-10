module RayyanFormats
  class Source
    attr_reader :name, :attachment

    def name=(value)
      raise "Invalid name: #{value}, must end with '.' then extension" unless value =~ /\..+/
      @name = value
    end

    def attachment=(value)
      @attachment = if value.nil?
        File.open(self.name)
      else
        [:size, :read, :close].each do |message|
          raise "Invalid attachment, must respond to :size, :read and :close" unless value.respond_to?(message)
        end
        value
      end
    end

    def initialize(_name, _attachment = nil)
      self.name = _name
      self.attachment = _attachment
    end
  end
end