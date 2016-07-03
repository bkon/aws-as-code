describe AwsAsCode::Task::Compile do
  let(:input_dir) { "INPUT" }
  let(:output_dir) { "OUTPUT" }
  let(:config) do
    double(
      "CONFIG",
      input_directory: input_dir,
      output_directory: output_dir
    )
  end

  subject(:task) { described_class.new config }

  it { should respond_to :execute }

  describe "#execute" do
    subject { task.execute }

    let(:input_files) { ["file1.rb", "file2.rb"] }

    before do
      allow(task).to receive :compile_single_file
      allow(task).to receive(:input_files).and_return input_files
    end

    it "attempts to compile all input files" do
      expect(task)
        .to receive(:compile_single_file)
        .with("file1.rb")
        .with("file2.rb")

      subject
    end
  end

  describe "#compile_single_file" do
    let(:input_dir) { Dir.mktmpdir }
    let(:output_dir) { Dir.mktmpdir }
    let(:input) { "file.rb" }
    subject { task.send :compile_single_file, File.join(input_dir, input) }

    before do
      input_pathname = File.join input_dir, input
      File.open(input_pathname, "w") do |f|
        f.write <<EOF
CloudFormation do
end
EOF
      end
    end

    after do
      FileUtils.remove_entry_secure input_dir
      FileUtils.remove_entry_secure output_dir
    end

    it "writes CFN template" do
      subject

      file = File.join output_dir, "file.json"
      expect(File.exist?(file)).to be_truthy
      expect(JSON.parse(File.read(file))).to_not be_nil
    end
  end

  describe "#input_files" do
    subject { task.send :input_files }
    let(:input_dir) { Dir.mktmpdir }

    before do
      FileUtils.touch File.join input_dir, "file1.rb"
      FileUtils.touch File.join input_dir, "file2.rb"

      nested = File.join input_dir, "nested"
      FileUtils.mkdir_p nested
      FileUtils.touch File.join nested, "file3.rb"
    end

    after do
      FileUtils.remove_entry_secure input_dir
    end

    it "returns a complete tree of rb files in the input dir" do
      expected_names = ["file1.rb", "file2.rb", "nested/file3.rb"].map { |file| File.join(input_dir, file) }
      # Note: file ordering may vary, hence `to_set`
      expect(subject.to_set).to eq expected_names.to_set
    end
  end
end
