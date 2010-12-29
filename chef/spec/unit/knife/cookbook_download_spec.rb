#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2010 Thomas Bishop
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::CookbookDownload do

  before(:each) do
    @knife = Chef::Knife::CookbookDownload.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @rest = mock("Chef::REST")

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  def set_expectations_for_cookbook_download
    @rest.should_receive(:get_rest).with("cookbooks/#{@cookbook_name}/#{@cookbook_version}").and_return(@cookbook_data)

    Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
      @chef_log_info_messages << "Downloading #{segment}"

      case segment
      when :files, :templates
        FileUtils.should_receive(:mkdir_p).with("#{@download_dir}/#{segment}/default")
      when :root_files

      else
        FileUtils.should_receive(:mkdir_p).with("#{@download_dir}/#{segment}")
      end

      @cookbook_data.manifest[segment].each do |segment_file|
        segment_file['url'] = "cookbooks/#{@cookbook_name}/#{@cookbook_version}/#{segment_file['name']}"
        @temp_file_mock = mock()
        @temp_file_mock.should_receive(:path).and_return("/var/tmp/#{segment_file['name']}")
        FileUtils.should_receive(:mv).with("/var/tmp/#{segment_file['name']}", "#{@download_dir}/#{segment_file['path']}")
        @rest.should_receive(:sign_on_redirect=).with(false)
        @rest.should_receive(:get_rest).with("cookbooks/#{@cookbook_name}/#{@cookbook_version}/#{segment_file['name']}", true).and_return(@temp_file_mock)
      end

    end
  end

  describe "run" do
    before(:each) do
      @cookbook_name = 'tatft'
      @cookbook_data = Chef::CookbookVersion.new(@cookbook_name)
      @cookbook = Hash.new { |hash, key| hash[key] = [] }
      cookbook_root = File.join(CHEF_SPEC_DATA, 'cb_version_cookbooks', @cookbook_name)

      cookbook_items = { 'attributes'   => { 'collection' => :attribute_filenames, 'files' => '*.rb' },
                         'definitions'  => { 'collection' => :definition_filenames, 'files' => '*.rb'},
                         'files'        => { 'collection' => :file_filenames, 'files' => '*.tgz'},
                         'recipes'      => { 'collection' => :recipe_filenames, 'files' => '*.rb'},
                         'templates'    => { 'collection' => :template_filenames, 'files' => '*.erb'},
                         'libraries'    => { 'collection' => :library_filenames, 'files' => '*.rb'},
                         'resources'    => { 'collection' => :resource_filenames, 'files' => '*.rb'},
                         'providers'    => { 'collection' => :provider_filenames, 'files' => '*.rb'}
      }

      cookbook_items.each_pair do |name, values|
        @cookbook[values['collection']] = Dir[File.join(cookbook_root, name, '**', values['files'])]
        @cookbook_data.send "#{values['collection']}=", @cookbook[values['collection']]
      end

      @cookbook[:root_filenames]        = Array(File.join(cookbook_root, 'README.rdoc'))
      @cookbook[:metadata_filenames]    = Array(File.join(cookbook_root, 'metadata.json'))
      @cookbook_data.root_filenames     = @cookbook[:root_filenames]
      @cookbook_data.metadata_filenames = @cookbook[:metadata_filenames]
    end

    describe "when providing a cookbook name" do
      before(:each) do
        @cookbook_version = '0.1.0'
        @knife.name_args = [@cookbook_name]
        @chef_log_info_messages = []
      end

      describe "and there is only one version of the cookbook" do
        before(:each) do
          @cookbook_data.version = @cookbook_version
          Chef::CookbookVersion.should_receive(:available_versions).with(@cookbook_name).and_return([@cookbook_version])
          @knife.stub!(:rest).and_return(@rest)
          @download_dir = "#{Dir.pwd}/#{@cookbook_name}-#{@cookbook_version}"
        end

        it "should download the cookbook into the current working directory" do
          FileUtils.should_receive(:mkdir_p).with(@download_dir)
          File.should_receive(:exists?).with(@download_dir).and_return(false)
          FileUtils.should_not_receive(:rm_rf).with(@download_dir)
          set_expectations_for_cookbook_download
          @knife.run
          @log_stringio.string.should match(Regexp.escape("INFO -- : Downloading #{@cookbook_name} cookbook version #{@cookbook_version}"))
          @log_stringio.string.should match(Regexp.escape("INFO -- : Cookbook downloaded to #{@download_dir}"))
          @chef_log_info_messages.count.should > 0
          @chef_log_info_messages.each do |message|
            @log_stringio.string.should match(Regexp.escape("INFO -- : #{message}"))
          end
        end

        it "should download the cookbook into the directory we specified with -d or --dir" do
          @knife.config[:download_directory] = '/var/foo/bar'
          @download_dir = "/var/foo/bar/#{@cookbook_name}-#{@cookbook_version}"
          File.should_receive(:exists?).with(@download_dir).and_return(false)
          FileUtils.should_not_receive(:rm_rf).with(@download_dir)
          FileUtils.should_receive(:mkdir_p).with(@download_dir)
          set_expectations_for_cookbook_download
          @knife.run
          @chef_log_info_messages.count.should > 0
          @chef_log_info_messages.each do |message|
            @log_stringio.string.should match(Regexp.escape("INFO -- : #{message}"))
          end
        end

        describe "and the download directory already exists" do
          it "should not download but should log an error and exit if we haven't specified to force the download" do
            lambda {
              @rest.should_receive(:get_rest).with("cookbooks/#{@cookbook_name}/#{@cookbook_version}").and_return(@cookbook_data)
              File.should_receive(:exists?).with(@download_dir).and_return(true)
              @knife.run
            }.should raise_error(SystemExit) { |e| e.status.should == 0 }
            @log_stringio.string.should match(Regexp.escape("INFO -- : Downloading #{@cookbook_name} cookbook version #{@cookbook_version}"))
            @log_stringio.string.should match(Regexp.escape("FATAL -- : Directory #{@download_dir} exists, use --force to overwrite"))
          end

          it "should remove the existing directory and download the cookbook when we specify -f or --force" do
            @knife.config[:force] = true
            FileUtils.should_receive(:mkdir_p).with(@download_dir)
            File.should_receive(:exists?).with(@download_dir).and_return(true)
            FileUtils.should_receive(:rm_rf).with(@download_dir).and_return(true)
            set_expectations_for_cookbook_download
            @knife.run
            @chef_log_info_messages.count.should > 0
            @chef_log_info_messages.each do |message|
              @log_stringio.string.should match(Regexp.escape("INFO -- : #{message}"))
            end
          end
        end

      end

      describe "and there are multiple versions of the cookbook" do
        before(:each) do
          @cookbook_version = '0.2.0'
          @cookbook_data.version = @cookbook_version
          @download_dir = "#{Dir.pwd}/#{@cookbook_name}-#{@cookbook_version}"
          Chef::CookbookVersion.should_receive(:available_versions).with(@cookbook_name).and_return(['0.1.0', @cookbook_version])
        end

        it "should download the latest version of the cookbook when we specify -N or --latest" do
          @knife.config[:latest] = true
          FileUtils.should_receive(:mkdir_p).with(@download_dir)
          File.should_receive(:exists?).with(@download_dir).and_return(false)
          set_expectations_for_cookbook_download
          @knife.stub!(:rest).and_return(@rest)
          @knife.run
          @chef_log_info_messages.count.should > 0
          @chef_log_info_messages.each do |message|
            @log_stringio.string.should match(Regexp.escape("INFO -- : #{message}"))
          end
        end

        it "should prompt us for a selection and log an error and exit when we specify an invalid option" do
          lambda {
          STDIN.stub!(:readline).and_return("10\n")
          @knife.run
          @stdout.string.should match(/Which version do you want to download\?\n1\. #{@cookbook_name} 0\.1\.0\n2\. #{@cookbook_name} 0\.2\.0\n\n/)
          }.should raise_error(SystemExit) { |e| e.status.should == 1 }
          @log_stringio.string.should match(Regexp.escape("'10' is not a valid value."))
        end

        it "should prompt us for a selection and download the version we select" do
          STDIN.stub!(:readline).and_return("2\n")
          FileUtils.should_receive(:mkdir_p).with(@download_dir)
          File.should_receive(:exists?).with(@download_dir).and_return(false)
          set_expectations_for_cookbook_download
          @knife.stub!(:rest).and_return(@rest)
          @knife.run
          @stdout.string.should match(/Which version do you want to download\?\n1\. #{@cookbook_name} 0\.1\.0\n2\. #{@cookbook_name} 0\.2\.0\n\n/)
          @chef_log_info_messages.count.should > 0
          @chef_log_info_messages.each do |message|
            @log_stringio.string.should match(Regexp.escape("INFO -- : #{message}"))
          end
        end
      end

    end

    describe "without a cookbook name" do
      it "should show the usage, log the error, and exit" do
        @knife.name_args = []
        lambda {
          @knife.should_receive(:show_usage)
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 1}
        @log_stringio.string.should match(Regexp.escape("You must specify a cookbook name"))
      end
    end

  end
end
