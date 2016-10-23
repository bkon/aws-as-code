require "tmpdir"
require "fileutils"

RSpec.describe AwsAsCode::Task::Upload do
  let(:config) do
    OpenStruct.new json_dir: "/home/user/cfn-compiled",
                   stack: "staging",
                   bucket: "test-bucket",
                   version: "VERSION"
  end

  let(:instance) { described_class.new config }

  describe "#execute" do
    subject { instance.execute }

    let(:first) { double("FIRST FILE") }
    let(:second) { double("SECOND FILE") }
    let(:third) { double("THIRD FILE") }

    before do
      allow(instance)
        .to receive(:input_files)
        .and_return [first, second, third]
    end

    it "uploads every input file" do
      expect(instance)
        .to receive(:upload_single_file)
        .with(first)

      expect(instance)
        .to receive(:upload_single_file)
        .with(second)

      expect(instance)
        .to receive(:upload_single_file)
        .with(third)

      instance.execute
    end
  end

  describe "#upload_single_file" do
    let(:filename) { "/home/user/cfn-compiled/subdir/file.json" }
    subject(:action) { instance.send :upload_single_file, filename }

    before do
      allow(instance)
        .to receive_message_chain(:bucket, :object, :upload_file)
    end

    it "uploads a file to S3 bucket" do
      expect(instance)
        .to receive_message_chain(:bucket, :object, :upload_file)
        .with(filename)

      action
    end

    it "users a relative path and stack name as a name for the new S3 object" do
      expect(instance)
        .to receive_message_chain(:bucket, :object)
        .with("staging/VERSION/subdir/file.json")

      action
    end
  end

  describe "#bucket" do
    subject(:action) { instance.send :bucket }

    let(:bucket) { double("bucket") }

    before do
      allow(Aws::S3::Resource)
        .to receive_message_chain(:new, :bucket)
        .and_return bucket
    end

    it "uses configured bucket name to access S3" do
      expect(Aws::S3::Resource)
        .to receive_message_chain(:new, :bucket)
        .with("test-bucket")

      action
    end

    it "return S3 bucket" do
      expect(subject).to eq bucket
    end
  end

  describe "#input_files" do
    subject(:action) { instance.send :input_files }

    let(:json_dir) { Dir.mktmpdir }

    let(:config) do
      OpenStruct.new json_dir: json_dir
    end

    before do
      FileUtils.touch File.join(json_dir, "1.json")
      FileUtils.touch File.join(json_dir, "2.txt")
      FileUtils.touch File.join(json_dir, "3.json")
    end

    after do
      FileUtils.remove_entry_secure json_dir
    end

    it "lists all json files in the configured dir" do
      expected = [
        File.join(json_dir, "1.json"),
        File.join(json_dir, "3.json")
      ]
      expect(action).to match_array expected
    end
  end
end
