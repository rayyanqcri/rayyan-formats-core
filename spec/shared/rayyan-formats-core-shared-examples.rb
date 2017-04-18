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

shared_examples "correct target emitter" do
  it "emits target if not nil (without abstracts)" do
    output = plugin.send(:do_export, target, {include_abstracts: false})
    expect(output).to eq(target_s)
  end

  it "emits target if not nil (with abstracts)" do
    output = plugin.send(:do_export, target, {include_abstracts: true})
    expect(output).to eq(target_s_abstracts)
  end

  it "does not emit target if nil" do
    output = plugin.send(:do_export, nil, {})
    expect(output).not_to eq(target_s)
  end
end