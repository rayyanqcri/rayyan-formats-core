require 'spec_helper'
require 'log4r'

module RayyanFormats
  module Plugins
    class Test < RayyanFormats::Base
      title 'test title'
      extension 'test extension'
      description 'test description'
      do_import do |body, filename, &block|
        next body * 2
      end
    end

    class TestCore < RayyanFormats::Base
      title 'test core title'
      extension 'test core extension'
      detect do |first_line, lines|
        next first_line
      end
      do_import do |body, filename, &block|
        next body
      end
    end
  end
end

include RayyanFormats

# logger = Log4r::Logger.new('RayyanFormats')
# logger.outputters = Log4r::Outputter.stdout
# RayyanFormats::Base.logger = logger

describe Base do
  let(:test_plugin) { Plugins::Test }
  let(:test_core_plugin) { Plugins::TestCore }

  describe "DSL" do
    let(:first_line) { "first_line" }
    let(:body) { "body" }

    [:title, :extension, :description].each do |attribute|
      it "identifies #{attribute}" do
        expect(test_plugin.send(attribute.to_sym)).to eq("test #{attribute}")
      end
    end

    it "identifies detect block" do
      expect(test_core_plugin.send(:detect, first_line)).to eq(first_line)
    end

    it "identifies do_import block" do
      expect(test_plugin.send(:do_import, body)).to eq(body * 2)
    end
  end

  describe ".is_core?" do
    it "returns false for wrapper (non core) plugins (having no detect block)" do
      expect(test_plugin.send(:is_core?)).to eq(false)
    end

    it "returns true for core plugins (having detect block)" do
      expect(test_core_plugin.send(:is_core?)).to eq(true)
    end
  end

  describe ".initialize_class" do
    # called implicitly
  end

  describe ".plugins" do
    it "returns default plugins without configuration" do
      expect(Base.plugins).to match_array([
        Plugins::PlainText,
        Plugins::CSV
      ])
    end

    it "returns configured plugins plus default plugins" do
      Base.plugins = [Plugins::Test]
      expect(Base.plugins).to match_array([
        Plugins::Test,
        Plugins::PlainText,
        Plugins::CSV
      ])
      Base.plugins = [] # to undo configuration
    end
  end

  describe ".max_file_size" do
    let(:configured_max_file_size) { 100 }

    it "returns default max_file_size without configuration" do
      expect(Base.max_file_size).to eq(Base::DEFAULT_MAX_FILE_SIZE)
    end

    it "returns configured max_file_size" do
      Base.max_file_size = configured_max_file_size
      expect(Base.max_file_size).to eq(configured_max_file_size)
    end
  end

  describe ".logger" do
    let(:message) { "log message" }
    let(:logger) { double }

    it "does nothing when asked to log messages and no logger configured" do
      expect(logger).not_to receive(:debug)
      Base.logger(message)
    end

    it "logs messages if a logger is configured" do
      Base.logger = logger
      expect(logger).to receive(:debug).with(message)
      Base.logger(message)
    end
  end

  describe ".extensions_str" do
    it "returns default extensions without configuration" do
      expect(Base.extensions_str).to eq("txt, csv")
    end

    it "returns extensions for configured plugins plus default plugins" do
      Base.plugins = [Plugins::Test]
      expect(Base.extensions_str).to eq("test extension, txt, csv")
      Base.plugins = [] # to undo configuration
    end
  end

  describe ".match_plugin" do
    it "returns nil if extension is not supported" do
      expect(Base.send(:match_plugin, 'unsupported')).to eq(nil)
    end

    context "when there is a matching plugin" do
      before {
        Base.plugins = [Plugins::Test, Plugins::TestCore]
      }

      after {
        Base.plugins = [] # to undo configuration
      }

      it "returns the matching plugin if it is not a core plugin" do
        expect(Base.send(:match_plugin, 'test extension')).to eq(Plugins::Test)
      end

      it "returns the plain text plugin if the matching plugin is core" do
        expect(Base.send(:match_plugin, 'test core extension')).to eq(Plugins::PlainText)
      end
    end
  end

  describe ".import" do
    let(:source_name) { "source_name.ext" }
    let(:content) { "place commercial here ;)" }
    let(:source_attachment) { double(size: 100, close: true, read: content) }
    let(:source) { double(name: source_name, attachment: source_attachment) }
    let(:plugin) { double }

    context "if no plugin is matching by extension" do
      before {
        allow(Base).to receive(:match_plugin).with("ext") { nil }
      }

      it "raises an exception" do
        expect{Base.import(source)}.to raise_error RuntimeError
      end
    end

    context "if file size is too big" do
      before {
        allow(Base).to receive(:match_plugin).with("ext") { plugin }
        allow(Base).to receive(:max_file_size) { 10 } # too small
      }

      it "raises an exception" do
        expect{Base.import(source)}.to raise_error RuntimeError
      end
    end

    context "if there is a matching plugin" do
      before {
        allow(Base).to receive(:match_plugin).with("ext") { plugin }
        allow(Base).to receive(:max_file_size) { 999 } # big enough
      }

      it "delegates to the plugin do_import" do
        expect(plugin).to receive(:do_import).with(content, source_name)
        Base.import(source)
      end
    end
  end

  describe ".detect_import_format" do
    it "raises an exception if input file is empty" do
      expect{Base.send(:detect_import_format, "")}.to raise_error RuntimeError
    end

    it "delegates to .detect_import_format_recursive" do
      detected = double
      expect(Base).to receive(:detect_import_format_recursive).with(%w(a b), 0) { detected }
      expect(Base.send(:detect_import_format, "a\nb")).to eq(detected)
    end
  end

  describe ".detect_import_format_recursive" do
    before {
      stub_const("RayyanFormats::Base::MAX_SKIP_LINES", 2)
      Base.plugins = [Plugins::Test, Plugins::TestCore]
    }

    after {
      Base.plugins = [] # to undo configuration
    }

    shared_examples 'a valid format detector' do
      it 'detects the format and returns the matching plugin and good lines' do
        expect(Base.send(:detect_import_format_recursive, lines, 0)).to \
          eq([plugin, good_lines])
      end
    end

    shared_examples 'an invalid format detector' do
      it 'detects the format and returns the matching plugin and good lines' do
        expect{Base.send(:detect_import_format_recursive, lines, 0)}.to \
          raise_error RuntimeError
      end
    end

    context "input is valid TestCore" do
      let(:good_lines) { %w(good1 good2) }
      let(:lines) { bad_lines + good_lines }

      before {
        allow(Plugins::TestCore).to receive(:detect).with(/^bad/, lines) { false }
        allow(Plugins::TestCore).to receive(:detect).with(/^good/, lines) { true }
        allow(Plugins::CSV).to receive(:detect) { false }
      }

      context "at first line" do
        let(:bad_lines) { [] }
        let(:plugin) { Plugins::TestCore }

        it_behaves_like 'a valid format detector'
      end

      context "after first line but before MAX_SKIP_LINES" do
        let(:bad_lines) { %w(bad1 bad2) }
        let(:plugin) { Plugins::TestCore }

        it_behaves_like 'a valid format detector'
      end

      context "after first line but after MAX_SKIP_LINES" do
        let(:bad_lines) { %w(bad1 bad2 bad3) }

        it_behaves_like 'an invalid format detector'
      end
    end

    context "input is CSV" do
      let(:header_line) { "1" }
      let(:body_lines) { %w(2 3 4) }
      let(:lines) { [header_line] + body_lines }
      let(:good_lines) { lines }
      let(:plugin) { Plugins::CSV }

      before {
        allow(Plugins::TestCore).to receive(:detect){ false }
        allow(Plugins::CSV).to receive(:detect).with(header_line, lines) { true }
      }

      it_behaves_like 'a valid format detector'
    end

    context "input is invalid" do
      before {
        allow(Plugins::TestCore).to receive(:detect){ false }
        allow(Plugins::CSV).to receive(:detect) { false }
      }

      context "and shorter than MAX_SKIP_LINES" do
        let(:lines) { %w(1) }

        it_behaves_like 'an invalid format detector'
      end

      context "and longer than MAX_SKIP_LINES" do
        let(:lines) { %w(1 2 3) }

        it_behaves_like 'an invalid format detector'
      end
    end
  end

  describe ".try_join_arr" do
    it "returns nil if input array is nil" do
      expect(Base.send(:try_join_arr, nil)).to eq(nil)
    end

    it "returns input if input does not responsd to join" do
      expect(Base.send(:try_join_arr, 100)).to eq(100)
    end

    it "returns input array joined in a string with new line as separator" do
      expect(Base.send(:try_join_arr, %w(a b c))).to eq("a\nb\nc")
    end

  end

end
