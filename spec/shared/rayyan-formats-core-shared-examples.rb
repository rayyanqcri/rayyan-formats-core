shared_examples "repetitive target yielder" do
  it "yields targets as many times as total articles found" do
    yielded = 0
    plugin.send(:do_import, body, filename) do |target, total|
      expect(total).to eq(expected_total)
      yielded += 1
    end
    expect(yielded).to eq(expected_total)
  end
end