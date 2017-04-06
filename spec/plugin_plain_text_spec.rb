require 'spec_helper'

include RayyanFormats::Plugins

describe PlainText do
  describe ".do_import" do
    let(:body) { "A sound mind is in a sound body" }
    let(:filename) { "you name it" }
    let(:plugin) { double(do_import: true) }
    let(:lines) { %w(a b) }

    it "detects correct plugin from content" do
      expect(PlainText).to receive(:detect_import_format).with(body){ [plugin, lines] }
      PlainText.send(:do_import, body, filename)
    end

    it "delegates to the do_import of the detected plugin" do
      allow(PlainText).to receive(:detect_import_format).with(body){ [plugin, lines] }
      expect(plugin).to receive(:do_import).with("a\nb", filename)
      PlainText.send(:do_import, body, filename)
    end
  end
end