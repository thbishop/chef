
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
require 'chef/cookbook_loader'

describe Chef::Knife::CookbookUpload do

  before(:each) do
    @knife = Chef::Knife::CookbookUpload.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger

    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    describe "without providing a cookbook name" do
      it "should log an error and exit" do
        lambda {
          @knife.should_receive(:show_usage)
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 1 }
        @log_stringio.string.should match(Regexp.escape('FATAL -- : You must specify the --all flag or at least one cookbook name'))
      end
    end

    describe "when providing a single cookbook name" do
      before(:each) do
        @cookbook_path = '/opt/chef/cookbooks'
        Chef::Config[:cookbook_path] = @cookbook_path
        @cookbook_name = 'pizza'
        @cookbook_loader_mock = mock()
        Chef::CookbookLoader.should_receive(:new).and_return(@cookbook_loader_mock)
        @manifest_mock = mock()
        Chef::Cookbook::FileVendor.should_receive(:on_create).and_yield(@manifest_mock)
        Chef::Cookbook::FileSystemFileVendor.should_receive(:new).with(@manifest_mock)
        @knife.name_args = [@cookbook_name]
      end

      it "should upload the cookbook" do
        @cookbook_loader_mock.should_receive(:cookbook_exists?).with(@cookbook_name).and_return(true)
        @cookbook_loader_mock.should_receive(:[]).with(@cookbook_name).and_return(@cookbook_name)
        Chef::CookbookUploader.should_receive(:upload_cookbook).with(@cookbook_name)
        @knife.run
      end

      it "should log an error if the cookbook can't be found" do
        @cookbook_loader_mock.should_receive(:cookbook_exists?).with(@cookbook_name).and_return(false)
        @knife.run
        @log_stringio.string.should match(Regexp.escape("ERROR -- : Could not find cookbook #{@cookbook_name} in your cookbook path, skipping it"))
      end

      it "should log an error and exit if there is an authentication error when trying to upload the cookbook" do
        lambda {
          @cookbook_loader_mock.should_receive(:cookbook_exists?).with(@cookbook_name).and_return(true)
           @cookbook_loader_mock.should_receive(:[]).with(@cookbook_name).and_return(@cookbook_name)
          response_mock = mock()
          response_mock.should_receive(:code).and_return("401")
          net_http_exception = Net::HTTPServerException.new('Not Authorized', response_mock)
          Chef::CookbookUploader.should_receive(:upload_cookbook).with(@cookbook_name).and_raise(net_http_exception)
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 18 }
        @log_stringio.string.should match(Regexp.escape("FATAL -- : Request failed due to authentication (Not Authorized), check your client configuration (username, key)"))
      end

      it "should log an error and exit if a non authentication related exception is encountered" do
        lambda {
          @cookbook_loader_mock.should_receive(:cookbook_exists?).with(@cookbook_name).and_return(true)
          @cookbook_loader_mock.should_receive(:[]).with(@cookbook_name).and_return(@cookbook_name)
          response_mock = mock()
          response_mock.should_receive(:code).and_return("500")
          net_http_exception = Net::HTTPServerException.new('Internal Server Error', response_mock)
          Chef::CookbookUploader.should_receive(:upload_cookbook).with(@cookbook_name).and_raise(net_http_exception)
          @knife.run
        }.should raise_error(Net::HTTPServerException)
      end

      describe "and with -o or --cookbook-path" do
        before(:each) do
          @knife.config[:cookbook_path] = '/usr/local/chef/cookbooks'
        end

        it "should use the path we specified and upload the cookbook" do
          @cookbook_loader_mock.should_receive(:cookbook_exists?).with(@cookbook_name).and_return(true)
          @cookbook_loader_mock.should_receive(:[]).with(@cookbook_name).and_return(@cookbook_name)
          Chef::CookbookUploader.should_receive(:upload_cookbook).with(@cookbook_name)
          @knife.run
          Chef::Config[:cookbook_path] = '/usr/local/chef/cookbooks'
        end

      end

    end

    describe "when providing multiple cookbook names" do
      before(:each) do
        @cookbook_path = '/opt/chef/cookbooks'
        Chef::Config[:cookbook_path] = @cookbook_path
        @cookbook_1_name = 'pizza'
        @cookbook_2_name = 'cheese'
        @cookbook_loader_mock = mock()
        @manifest_mock = mock()
        Chef::Cookbook::FileVendor.should_receive(:on_create).and_yield(@manifest_mock)
        Chef::Cookbook::FileSystemFileVendor.should_receive(:new).with(@manifest_mock)
        @knife.name_args = [@cookbook_1_name, @cookbook_2_name]
      end

      it "should upload all of the cookbooks we specified" do
        Chef::CookbookLoader.should_receive(:new).and_return(@cookbook_loader_mock)
        [@cookbook_1_name, @cookbook_2_name].each do |cookbook_name|
          @cookbook_loader_mock.should_receive(:cookbook_exists?).with(cookbook_name).and_return(true)
          @cookbook_loader_mock.should_receive(:[]).with(cookbook_name).and_return(cookbook_name)
          Chef::CookbookUploader.should_receive(:upload_cookbook).with(cookbook_name)
        end

        @knife.run
      end
    end

    describe "with -a or --all" do
      before(:each) do
        @cookbook_path = '/opt/chef/cookbooks'
        Chef::Config[:cookbook_path] = @cookbook_path
        @manifest_mock = mock()
        Chef::Cookbook::FileVendor.should_receive(:on_create).and_yield(@manifest_mock)
        Chef::Cookbook::FileSystemFileVendor.should_receive(:new).with(@manifest_mock)
        @cookbook_1_name = 'pizza'
        @cookbook_1_mock = mock()
        @cookbook_2_name = 'cheese'
        @cookbook_2_mock = mock()
        @cookbook_3_name = 'dough'
        @cookbook_3_mock = mock()
        @cookbook_loader_mock = mock()
        @knife.config[:all] = true
      end

      it "should upload all of the cookbooks" do
        {@cookbook_1_name => @cookbook_1_mock, @cookbook_2_name => @cookbook_2_mock, @cookbook_3_name => @cookbook_3_mock}.each_pair do |cookbook_name, cookbook_mock|
          cookbook_mock.should_receive(:name).and_return(cookbook_name)
          Chef::CookbookUploader.should_receive(:upload_cookbook).with(cookbook_mock)
        end
        Chef::CookbookLoader.should_receive(:new).and_return(@cookbook_loader_mock)
        @cookbook_loader_mock.should_receive(:each).and_yield(@cookbook_1_name, @cookbook_1_mock).and_yield(@cookbook_2_name, @cookbook_2_mock).and_yield(@cookbook_3_name, @cookbook_3_mock)
        @knife.run
        @log_stringio.string.should match(Regexp.escape("INFO -- : ** #{@cookbook_1_name} **"))
        @log_stringio.string.should match(Regexp.escape("INFO -- : ** #{@cookbook_2_name} **"))
        @log_stringio.string.should match(Regexp.escape("INFO -- : ** #{@cookbook_3_name} **"))
      end
    end

  end
end
