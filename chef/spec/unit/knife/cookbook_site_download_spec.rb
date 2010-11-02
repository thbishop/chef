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

describe Chef::Knife::CookbookSiteDownload do

  def should_download_the_cookbook(file)
    @rest.should_receive(:get_rest).with("http://cookbooks.opscode.com/api/v1/cookbooks/#{@cookbook_name}/versions/#{@cookbook_version.gsub('.', '_')}").and_return(@cookbook_data)
    Chef::Log.should_receive(:info).with("Downloading #{@cookbook_name} from the cookbooks site at version #{@cookbook_version}")
    @rest.should_receive(:sign_on_redirect=).with(false)
    @file_mock.should_receive(:path).and_return("#{@cookbook_name}.tgz")
    @rest.should_receive(:get_rest).with("http://s3.amazonaws.com/opscode-community/cookbook_versions/tarballs/387/original/#{@cookbook_name}-#{@cookbook_version}.tgz", true).and_return(@file_mock)
    FileUtils.should_receive(:cp).with("#{@cookbook_name}.tgz", file)
    Chef::Log.should_receive(:info).with("Cookbook saved: #{file}")
    @knife.stub!(:rest).and_return(@rest)
  end

  before(:each) do
    @knife = Chef::Knife::CookbookSiteDownload.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @rest = mock("Chef::REST")
  end

  describe "run" do
    describe "when providing a cookbook name" do
      before(:each) do
        @cookbook_name = 'pizza'
        @cookbook_version = '0.1.6'
        @knife.name_args = [@cookbook_name]
        @cookbook_index_data = { 'latest_version' => "http://cookbooks.opscode.com/api/v1/cookbooks/#{@cookbook_name}/versions/#{@cookbook_version.gsub('.', '_')}" }
        @cookbook_data = { 'version' => @cookbook_version, 
                           'file' => "http://s3.amazonaws.com/opscode-community/cookbook_versions/tarballs/387/original/#{@cookbook_name}-#{@cookbook_version}.tgz" }
        @file_mock = mock()
      end

      it "should download the latest version into the current working directory" do
        @rest.should_receive(:get_rest).with("http://cookbooks.opscode.com/api/v1/cookbooks/#{@cookbook_name}").and_return(@cookbook_index_data)
        should_download_the_cookbook("#{Dir.pwd}/pizza-0.1.6.tar.gz")
        @knife.run
      end

      it "should download the latest version to path specified with -f or --file" do
        @knife.config[:file] = "/var/tmp/#{@cookbook_name}-cookbook.tar.gz"
        @rest.should_receive(:get_rest).with("http://cookbooks.opscode.com/api/v1/cookbooks/#{@cookbook_name}").and_return(@cookbook_index_data)
        should_download_the_cookbook("/var/tmp/#{@cookbook_name}-cookbook.tar.gz")
        @knife.run
      end

      describe "and a version" do
        before(:each) do
          @cookbook_version = '1.0.2'
          @knife.name_args << @cookbook_version
          @cookbook_data = { 'version' => "#{@cookbook_version}",
                             'file' => "http://s3.amazonaws.com/opscode-community/cookbook_versions/tarballs/387/original/#{@cookbook_name}-#{@cookbook_version}.tgz" }
        end

        it "should download the version we requested" do
          @rest.should_not_receive(:get_rest).with("http://cookbooks.opscode.com/api/v1/cookbooks/#{@cookbook_name}")
          should_download_the_cookbook("#{Dir.pwd}/pizza-1.0.2.tar.gz")
          @knife.run
        end
      end
    end

  end

end