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
require 'fog'

describe Chef::Knife::RackspaceServerDelete do
  before(:each) do
    @knife = Chef::Knife::RackspaceServerDelete.new

    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    STDOUT.stub!(:print).and_return(@stdout)
    STDOUT.stub!(:puts).and_return(@stdout)

    @knife = Chef::Knife::RackspaceServerDelete.new
    @rackspace_connection = mock()
    @rackspace_servers = mock()
    @existing_rackspace_server = mock()
    @rackspace_connection.should_receive(:servers).and_return(@rackspace_servers)

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger

    Chef::Config[:knife][:rackspace_api_key] = 'my-api-key'
    Chef::Config[:knife][:rackspace_api_username] = 'my-api-username'
    Fog::Rackspace::Servers.should_receive(:new).and_return(@rackspace_connection)
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    before(:each) do
      @knife.name_args = [37465]
      @rackspace_servers.should_receive(:get).with(37465).and_return(@existing_rackspace_server)
    end

    it "should delete the server when we confirm to do so" do
      @existing_rackspace_server.should_receive(:id).twice.and_return(37465)
      @existing_rackspace_server.should_receive(:name).twice.and_return('web01')
      @knife.should_receive(:confirm).with('Do you really want to delete server ID 37465 named web01')
      @existing_rackspace_server.should_receive(:destroy).and_return(true)
      @knife.run
      @log_stringio.string.should match(Regexp.escape('WARN -- : Deleted server 37465 named web01'))
    end

    it "should not delete the server we do not confirm to do so" do
      lambda {
        @existing_rackspace_server.should_receive(:id).and_return(37465)
        @existing_rackspace_server.should_receive(:name).and_return('web01')
        @knife.stub!(:stdin).and_return(StringIO.new("N\n"))
        @existing_rackspace_server.should_not_receive(:destroy)
        @knife.run
        @log_stringio.string.should_not match(Regexp.escape('WARN -- : Deleted server'))
      }.should raise_error(SystemExit)
    end
  end
end
