#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) Thomas Bishop
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
  def should_generate_the_cookbook_metadata(cookbook_name, cookbook_path)
    cookbook_metadata_rb_file = "#{cookbook_path}/#{cookbook_name}/metadata.rb"
    cookbook_metadata_json_file = "#{cookbook_path}/#{cookbook_name}/metadata.json"

    Chef::Log.should_receive(:info).with("Generating Metadata")
    Chef::Log.should_receive(:debug).with("Generating metadata for #{cookbook_name} from #{cookbook_metadata_rb_file}")
    Chef::Log.should_receive(:debug).with("Generated #{cookbook_metadata_json_file}")
    File.should_receive(:exists?).with(cookbook_metadata_rb_file).and_return(true)

    @cookbook_metadata = mock()
    @cookbook_metadata.should_receive(:name)
    @cookbook_metadata.should_receive(:from_file).with(cookbook_metadata_rb_file)
    Chef::Cookbook::Metadata.should_receive(:new).and_return(@cookbook_metadata)

    @json_file_mock = mock()
    @json_file_mock.should_receive(:write).and_return(true)
    JSON.should_receive(:pretty_generate).with(@cookbook_metadata).and_return(true)
    File.should_receive(:open).with(cookbook_metadata_json_file, "w").and_yield(@json_file_mock)
  end

  before(:each) do
    @knife = Chef::Knife::CookbookMetadata.new
  end

  describe "run" do
    describe "when providing a cookbook name" do
      before(:each) do
        @cookbook_name = 'foo'
        @knife.name_args = [@cookbook_name]
      end

      describe "without any arguments" do
        before(:each) do
          @cookbook_path = '/var/foo/chef/cookbooks'
          Chef::Config[:cookbook_path] = @cookbook_path
          @metadata_rb_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.rb"
          @metadata_json_file = "#{@cookbook_path}/#{@cookbook_name}/metadata.json"
        end

        it "should generate the metadata for the cookbook" do
          should_generate_the_cookbook_metadata(@cookbook_name, @cookbook_path)
          @knife.run
        end

        it "should not generate the metatdata if the cookbook metadata file doesn't exist" do
          Chef::Log.should_receive(:info).with("Generating Metadata")
          File.should_receive(:exists?).with(@metadata_rb_file).and_return(false)
          Chef::Log.debug("No #{@metadata_rb_file} found; skipping!")
          @knife.run
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
          should_generate_the_cookbook_metadata(@cookbook_name, @cookbook_path)
          @knife.run
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
        end

        it "should generate the metatdata for each cookbook" do
          @cookbook_loader = mock()
          @cookbook_loader.should_receive(:each).and_yield('foo', 'foo').and_yield('bar', 'bar').and_yield('baz', 'baz')
          Chef::CookbookLoader.should_receive(:new).and_return(@cookbook_loader)
          @cookbooks.each do |cookbook|
            should_generate_the_cookbook_metadata(cookbook, @cookbook_path)
          end
          @knife.run
        end
      end

    end

  end
end
