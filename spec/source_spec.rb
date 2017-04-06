require 'spec_helper'

include RayyanFormats

describe Source do
  describe ".initialize" do
    context "initializing with name" do
      before {
        allow_any_instance_of(Source).to receive(:attachment=)
      }

      context "with missing name" do
        let(:source_name) { nil }

        it "does not accept missing name" do
          expect {
            Source.new(source_name)
          }.to raise_error RuntimeError
        end
      end

      context "with invalid name" do
        let(:source_name) { "source_name_without_extension" }

        it "does not accept invalid name" do
          expect {
            Source.new(source_name)
          }.to raise_error RuntimeError
        end
      end

      context "with valid name" do
        let(:source_name) { "source_name.extension" }

        it "accepts valid name" do
          source = Source.new(source_name)
          expect(source.name).to eq(source_name)
        end
      end
    end

    context "initializing with attachment" do
      let(:source_name) { double }

      before {
        allow_any_instance_of(Source).to receive(:name=)
        allow_any_instance_of(Source).to receive(:name) { source_name }
      }

      context "with missing attachment" do
        let(:source_attachment) { double }
        let(:source) { Source.new(nil) }

        before {
          allow(File).to receive(:open).with( source_name ) { source_attachment }
        }

        it "opens the file specified by name" do
          expect(source.attachment).to eq(source_attachment)
        end
      end

      context "with invalid attachment" do
        let(:source_attachment) { "not an IO object" }
        let(:source) { Source.new(nil, source_attachment) }

        it "does not accept invalid attachment" do
          expect {
            source
          }.to raise_error RuntimeError
        end
      end

      context "with valid attachment" do
        let(:source_attachment) { double(size: 1, read: "x", close: true) }
        let(:source) { Source.new(nil, source_attachment) }

        it "accepts valid attachment" do
          expect(source.attachment).to eq(source_attachment)
        end
      end
    end
  end
end