require "tmpdir"
require "fileutils"

describe AwsAsCode::Task::Compile do
  let(:ruby_dir) { "INPUT" }
  let(:json_dir) { "OUTPUT" }
  let(:config_dir) { "CONFIG" }

  let(:config) do
    OpenStruct.new ruby_dir: ruby_dir,
                   json_dir: json_dir,
                   config_dir: config_dir,
                   stack: "staging",
                   bucket: "test-bucket",
                   version: "VERSION"
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
    let(:config_dir) { Dir.mktmpdir }
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

      config_pathname = File.join config_dir, "parameters.yml"
      File.open(config_pathname, "w") do |f|
        f.write <<EOF
RailsSecretKeyBase:
  Type: String
  Default: test
  _ext:
    env: RAILS_SECRET_KEY_BASE
    secure: true
EOF
      end

      settings_pathname = File.join config_dir, "settings.yml"
      File.open(settings_pathname, "w") do |f|
        f.write <<EOF
zone:
  _default: test.com
domain:
  _default: staging
EOF
      end
    end

    after do
      FileUtils.remove_entry_secure ruby_dir
      FileUtils.remove_entry_secure json_dir
      FileUtils.remove_entry_secure config_dir
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

  describe "dynamic methods" do
    describe "params" do
      let(:params) do
        YAML.load(
          <<YAML
Param1:
  Type: String
  Default: test
  _ext:
    env: ENV1
    secure: true
Param2:
  Type: String
  Default: test
  _ext:
    env: ENV2
    secure: true
    services:
      - s1
      - s2
Param3:
  Type: String
  Default: test
  _ext:
    env: ENV2
    secure: true
    services:
      - s1
Param4:
  Type: String
  Default: test
  _ext:
    env: ENV2
    secure: true
    services:
      - s2
YAML
          ).to_a
      end

      subject do
        allow(task).to receive(:load_params).and_return params.to_a
        task.send :def_params
        CfnDsl::JSONable.new.params "s1"
      end

      it "includes items without a service restriction" do
        expect(subject).to have_key "Param1"
      end

      it "includes items matching current service" do
        expect(subject).to have_key "Param2"
        expect(subject).to have_key "Param3"
      end

      it "does not include items mismatching current service" do
        expect(subject).to_not have_key "Param4"
      end
    end

    describe "setting" do
      let(:settings) do
        YAML.load(
          <<YAML
key1:
  production: PROD1
  _default: FALLBACK1
key2:
  _default: FALLBACK2
YAML
          )
      end

      let(:config) do
        OpenStruct.new stack: "production"
      end

      subject do
        allow(task).to receive(:load_settings).and_return settings
        allow(task).to receive(:config).and_return config
        task.send :def_settings
        CfnDsl::JSONable.new.setting key
      end

      context "when setting has stack-specific value" do
        let(:key) { "key1" }
        let(:stack_specific_value) { "PROD1" }
        it { should eq stack_specific_value }
      end

      context "when setting has no stack-specific value" do
        let(:key) { "key2" }
        let(:default_value) { "FALLBACK2" }
        it { should eq default_value }
      end
    end

    describe "template_url" do
      let(:config) do
        OpenStruct.new stack: "production",
                       version: "VERSION",
                       bucket: "bucket"
      end

      before do
        allow(task).to receive(:config).and_return config
      end

      subject do
        task.send :def_template_url
        CfnDsl::JSONable.new.template_url "dir/name"
      end

      let(:s3_url) do
        "https://s3.amazonaws.com/bucket/production/VERSION/dir/name.json"
      end

      it { should eq s3_url }
    end
  end
end
