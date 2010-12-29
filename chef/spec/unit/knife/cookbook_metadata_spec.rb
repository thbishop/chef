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

describe Chef::Knife::CookbookMetadata do
  before(:each) do
    @knife = Chef::Knife::CookbookMetadata.new
    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  def set_cookbook_generate_expectations
    cookbook_metadata_rb_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.rb"
    cookbook_metadata_json_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.json"

    @chef_log_info_messages << 'Generating Metadata'
    @chef_log_debug_messages << "Generating metadata for #{@cookbook_name} from #{cookbook_metadata_rb_file}"
    @chef_log_debug_messages << "Generated #{cookbook_metadata_json_file}"
    File.should_receive(:exists?).with(cookbook_metadata_rb_file).and_return(true)

    @cookbook_metadata = mock()
    @cookbook_metadata.should_receive(:name)
    @cookbook_metadata.should_receive(:from_file).with(cookbook_metadata_rb_file)
    Chef::Cookbook::Metadata.should_receive(:new).and_return(@cookbook_metadata)

    @json_file_mock = mock()
    @json_file_mock.should_receive(:write).and_return(true)
    Chef::JSON.should_receive(:to_json_pretty).with(@cookbook_metadata).and_return(true)
    File.should_receive(:open).with(cookbook_metadata_json_file, "w").and_yield(@json_file_mock)
  end

  describe "run" do
    describe "when providing a cookbook name" do
      before(:each) do
        @cookbook_name = 'foo'
        @knife.name_args = [@cookbook_name]
        @chef_log_info_messages = []
        @chef_log_debug_messages = []
      end

      describe "without any arguments" do
        before(:each) do
          @cookbook_path = '/var/foo/chef/cookbooks'
          Chef::Config[:cookbook_path] = @cookbook_path
          @metadata_rb_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.rb"
          @metadata_json_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.json"
        end

        it "should generate the metadata for the cookbook" do
          set_cookbook_generate_expectations
          @knife.run
          { @chef_log_info_messages => 'INFO', @chef_log_debug_messages => 'DEBUG' }.each_pair do |messages, type|
            messages.count.should > 0
            messages.each do |message|
              @log_stringio.string.should match(Regexp.escape("#{type} -- : #{message}"))
            end
          end
        end

        it "should not generate the metatdata if the cookbook metadata file doesn't exist" do
          File.should_receive(:exists?).with(@metadata_rb_file).and_return(false)
          @knife.run
          @log_stringio.string.should match(Regexp.escape("INFO -- : Generating Metadata"))
          @log_stringio.string.should match(Regexp.escape("DEBUG -- : No #{@metadata_rb_file} found; skipping!"))
        end
      end

      describe "and specifying a path with -o or --cookbook-path" do
        before(:each) do
          @cookbook_path = '/var/bar/chef/cookbooks'
          @knife.config[:cookbook_path] = @cookbook_path
          @metadata_rb_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.rb"
          @metadata_json_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.json"
        end

        it "should generate the metadata for our cookbook" do
          set_cookbook_generate_expectations
          @knife.run
          { @chef_log_info_messages => 'INFO', @chef_log_debug_messages => 'DEBUG' }.each_pair do |messages, type|
            messages.count.should > 0
            messages.each do |message|
              @log_stringio.string.should match(Regexp.escape("#{type} -- : #{message}"))
            end
          end
        end
      end

    end

    describe "without providing a cookbook name" do
      describe "and specifying all cookbooks with -a or --all" do
        before(:each) do
          @cookbook_path = '/var/chef/cookbooks'
          Chef::Config[:cookbook_path] = @cookbook_path
          @knife.config[:all] = true
          @cookbooks = ['foo', 'bar', 'baz']
          @chef_log_info_messages = []
          @chef_log_debug_messages = []
        end

        it "should generate the metatdata for each cookbook" do
          @cookbook_loader = mock()
          @cookbook_loader.should_receive(:each).and_yield('foo', 'foo').and_yield('bar', 'bar').and_yield('baz', 'baz')
          Chef::CookbookLoader.should_receive(:new).and_return(@cookbook_loader)
          @cookbooks.each do |cookbook|
            @cookbook_name = cookbook
            set_cookbook_generate_expectations
          end
          @knife.run
          { @chef_log_info_messages => 'INFO', @chef_log_debug_messages => 'DEBUG' }.each_pair do |messages, type|
            messages.count.should > 0
            messages.each do |message|
              @log_stringio.string.should match(Regexp.escape("#{type} -- : #{message}"))
            end
          end
        end
      end

    end

  end
end
