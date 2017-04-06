require 'spec_helper'

include RayyanFormats

describe Target do
  let(:target) { Target.new }

  describe ".initialize" do
    it "creates a new instance" do
      expect(target.class).to eq(Target)
    end
  end

  describe "#to_s" do
    it "serializes the internal dictionary" do
      target.a, target.b = 1, 2
      expect(target.to_s).to eq("{:a=>1, :b=>2}")
    end
  end

  describe "#method_missing" do
    let(:key) { rand.to_s }
    let(:val) { rand.to_s }

    it "accepts assignment of any variable" do
      target.send("#{key}=".to_sym, val)
      expect(target.send(key.to_sym)).to eq(val)
    end

    it "returns nil for unseen getters" do
      expect(target.send(key.to_sym)).to eq(nil)
    end
  end
end