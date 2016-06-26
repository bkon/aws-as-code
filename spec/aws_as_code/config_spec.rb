describe AwsAsCode::Config do
  subject { AwsAsCode::Config.new }

  it "knows the location of the input directory" do
    expect(subject).to respond_to :input_directory
  end
end
