describe AwsAsCode::Config do
  let(:params) { Hash[] }
  subject { AwsAsCode::Config.new params }

  it "knows the location of the input directory" do
    expect(subject).to respond_to :input_directory
  end

  it "knows the location of the output directory" do
    expect(subject).to respond_to :output_directory
  end

  context "when no parameters are provided" do
    let(:params) { Hash[] }
    it "provides a default value for the input directory" do
      expect(subject.input_directory).to eq "input"
    end

    it "provides a default value for the input directory" do
      expect(subject.output_directory).to eq "output"
    end
  end

  context "when initialzied parameters are provided" do
    let(:input_directory) { "custom/input" }
    let(:output_directory) { "custom/output" }

    let(:params) do
      Hash[
        input_directory: input_directory,
        output_directory: output_directory
      ]
    end

    it "uses provided value for the input directory" do
      expect(subject.input_directory).to eq input_directory
    end

    it "uses provided value for the output directory" do
      expect(subject.output_directory).to eq output_directory
    end
  end
end
