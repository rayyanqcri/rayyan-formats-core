require 'spec_helper'

describe RayyanFormats::Plugins::CSV do
  describe ".detect" do
    let(:header) { 'x ,TiTle ,y' }
    let(:body_lines) { ['a1,a2,a3', 'b1,b2,b3', 'c1,c2,c3'] }
    let(:lines) { [header] + body_lines }

    shared_examples 'a csv detector' do
      it 'accepts a valid csv input and rejects an invalid input' do
        expect(RayyanFormats::Plugins::CSV.send(:detect, header, lines)).to eq(is_csv?)
      end
    end

    context "when header contains title and number of columns matches header" do
      let(:is_csv?) { true }

      it_behaves_like 'a csv detector'
    end

    context "when header does not contain title" do
      let(:header) { 'x ,no title,y' }
      let(:is_csv?) { false }

      it_behaves_like 'a csv detector'
    end

    context "when number of columns in any of the first few body lines is less than those of header" do
      let(:body_lines) { ['a1,a2,a3', 'b1,b2,b3', 'c1,c2', 'd1,d2,d3,d4'] }

      before {
        stub_const("RayyanFormats::Plugins::CSV::MAX_CSV_ROWS_DETECT", 10)
      }

      let(:is_csv?) { false }

      it_behaves_like 'a csv detector'
    end

    context "when number of columns in any of the late body lines is less than those of header" do
      let(:body_lines) { ['a1,a2,a3', 'b1,b2,b3', 'c1,c2'] }

      before {
        stub_const("RayyanFormats::Plugins::CSV::MAX_CSV_ROWS_DETECT", 2)
      }

      # gets deceived and returns true
      let(:is_csv?) { true }

      it_behaves_like 'a csv detector'
    end
  end

  describe ".do_import" do
    let(:filename) { 'spec/support/example1.csv' }
    let(:body) { File.open(filename) }
    let(:expected_total) { 2 }

    it "yields as many times as total articles found" do
      yielded = 0
      RayyanFormats::Plugins::CSV.send(:do_import, body, filename) do |target, total|
        expect(total).to eq(expected_total)
        yielded += 1
      end
      expect(yielded).to eq(expected_total)
    end

    it "assigns correct values from first line" do
      first_line = true
      RayyanFormats::Plugins::CSV.send(:do_import, body, filename) do |target|
        if first_line
          expect(target.sid).to eq("key1")
          expect(target.title).to eq("title1")
          expect(target.date_array).to eq([2017])
          expect(target.jvolume).to eq(1)
          expect(target.jissue).to eq(10)
          expect(target.pagination).to eq("pages1")
          expect(target.authors).to eq(["a1l, a1f", "a2l, a2f", "a3l, a3f"])
          expect(target.url).to eq("url1")
          expect(target.language).to eq("lang1")
          expect(target.notes).to eq("notes1")
          expect(target.abstracts).to eq(["abstract1"])
          expect(target.publication_types).to eq(["Journal Article"])
          expect(target.publisher_name).to eq("publisher1")
          expect(target.publisher_location).to eq("location1")
          expect(target.journal_title).to eq("journal1")
          expect(target.journal_issn).to eq("issn1")
        end
        first_line = false
      end
    end
  end
end