require "tmpdir"
require "fileutils"

describe AwsAsCode::Task::Compile do
  let(:ruby_dir) { "INPUT" }
  let(:json_dir) { "OUTPUT" }
  let(:config) do
    double(
      "CONFIG",
      ruby_dir: ruby_dir,
      json_dir: json_dir
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
    let(:ruby_dir) { Dir.mktmpdir }
    let(:json_dir) { Dir.mktmpdir }
    let(:input) { "file.rb" }
    subject { task.send :compile_single_file, File.join(ruby_dir, input) }

    before do
      input_pathname = File.join ruby_dir, input
      File.open(input_pathname, "w") do |f|
        f.write <<EOF
CloudFormation do
end
EOF
      end
    end

    after do
      FileUtils.remove_entry_secure ruby_dir
      FileUtils.remove_entry_secure json_dir
    end

    it "writes CFN template" do
      subject

      file = File.join json_dir, "file.json"
      expect(File.exist?(file)).to be_truthy
      expect(JSON.parse(File.read(file))).to_not be_nil
    end
  end

  describe "#input_files" do
    subject { task.send :input_files }
    let(:ruby_dir) { Dir.mktmpdir }

    before do
      FileUtils.touch File.join ruby_dir, "file1.rb"
      FileUtils.touch File.join ruby_dir, "file2.rb"

      nested = File.join ruby_dir, "nested"
      FileUtils.mkdir_p nested
      FileUtils.touch File.join nested, "file3.rb"
    end

    after do
      FileUtils.remove_entry_secure ruby_dir
    end

    it "returns a complete tree of rb files in the input dir" do
      expected_names = ["file1.rb", "file2.rb", "nested/file3.rb"].map { |file| File.join(ruby_dir, file) }
      # Note: file ordering may vary, hence `to_set`
      expect(subject.to_set).to eq expected_names.to_set
    end
  end
end
