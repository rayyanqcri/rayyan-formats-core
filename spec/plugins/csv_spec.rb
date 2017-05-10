require 'spec_helper'
require 'rayyan-formats-core-shared-examples'

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

    context "when header contains title" do
      let(:is_csv?) { true }

      it_behaves_like 'a csv detector'
    end

    context "when header does not contain title" do
      let(:header) { 'x ,no title,y' }
      let(:is_csv?) { false }

      it_behaves_like 'a csv detector'
    end
  end

  describe ".do_import" do
    let(:filename) { 'spec/support/example1.csv' }
    let(:body) { File.read(filename) }
    let(:expected_total) { 2 }
    let(:plugin) { RayyanFormats::Plugins::CSV }

    it_behaves_like "repetitive target yielder"

    it "assigns correct values from first line" do
      first_line = true
      plugin.send(:do_import, body, filename) do |target|
        if first_line
          expect(target.publication_types).to eq(["Journal Article"])
          expect(target.sid).to eq("key1")
          expect(target.title).to eq("title1")
          expect(target.date_array).to eq(["2017", "5", "4"])
          expect(target.journal_title).to eq("journal1")
          expect(target.journal_issn).to eq("issn1")
          expect(target.jvolume).to eq(1)
          expect(target.jissue).to eq(10)
          expect(target.pagination).to eq("pages1")
          expect(target.authors).to eq(["a1l, a1f", "a2l, a2f", "a3l, a3f"])
          expect(target.url).to eq("url1")
          expect(target.language).to eq("lang1")
          expect(target.publisher_name).to eq("publisher1")
          expect(target.publisher_location).to eq("location1")
          expect(target.abstracts).to eq(["abstract1"])
          expect(target.notes).to eq("notes1")
        end
        first_line = false
      end
    end
  end

  describe ".do_export" do
    let(:plugin) { RayyanFormats::Plugins::CSV }
    let(:target) {
      t = RayyanFormats::Target.new
      t.sid = 'key1'
      t.title = 'title1'
      t.date_array = [2017, 5, 4]
      t.journal_title = 'journal1'
      t.journal_issn = 'issn1'
      t.jvolume = 1
      t.jissue = 10
      t.pagination = 'pages1'
      t.authors = ['al1, af1', 'al2, af2']
      t.url = 'url1'
      t.language = 'lang1'
      t.publisher_name = 'publisher1'
      t.publisher_location = 'location1'
      t.abstracts = ['abstract1', 'abstract2']
      t.notes = 'notes1'
      t
    }
    let(:target_s_abstracts) {
      "key1,title1,2017,5,4,journal1,issn1,1,10,pages1,\"al1, af1 and al2, af2\",url1,lang1,publisher1,location1,\"abstract1\nabstract2\",notes1\n"
    }
    let(:target_s) {
      "key1,title1,2017,5,4,journal1,issn1,1,10,pages1,\"al1, af1 and al2, af2\",url1,lang1,publisher1,location1,,notes1\n"
    }
    let(:header) {
      "key,title,year,month,day,journal,issn,volume,issue,pages,authors,url,language,publisher,location,abstract,notes\n"
    }

    it "emits header if specified" do
      output = plugin.send(:do_export, nil, {include_header: true})
      expect(output).to eq(header)
    end

    it "does not emit header of not specified" do
      output = plugin.send(:do_export, nil, {include_header: false})
      expect(output).not_to eq(header)
    end

    it "emits header and target if both specified" do
      output = plugin.send(:do_export, target, {include_header: true})
      expect(output).to eq(header + target_s)
    end

    it_behaves_like "correct target emitter"   
  end
end