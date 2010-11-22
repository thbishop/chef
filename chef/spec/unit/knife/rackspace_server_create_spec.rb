
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
require 'highline'

describe Chef::Knife::RackspaceServerCreate do
  before(:each) do
    @stdout = StringIO.new
    $stdout = @stdout
    @knife.stub!(:puts).and_return(@stdout)
    @knife.stub!(:stdout).and_return(@stdout)
    @knife.stub!(:print).and_return(@stdout)

    @h = HighLine.new

    @knife = Chef::Knife::RackspaceServerCreate.new
    @knife.name_args = ['role[base]']
    @knife.initial_sleep_delay = 0
    @rackspace_connection = mock()
    @rackspace_servers = mock()
    @new_rackspace_server = mock()
    @bootstrap_mock = mock()
    @rackspace_connection.should_receive(:servers).and_return(@rackspace_servers)

    Chef::Config[:chef_server_url] = 'https://my-chef-server.example.com'
    Chef::Config[:validation_client_name] = 'my-validation-client'
    Chef::Config[:knife][:rackspace_api_key] = 'my-api-key'
    Chef::Config[:knife][:rackspace_api_username] = 'my-api-username'

    Fog::Rackspace::Servers.should_receive(:new).and_return(@rackspace_connection)
  end

  describe "run" do
    before(:each) do
      @knife.stub!(:tcp_test_ssh).and_return(true)
      @addresses_mock = mock()
      @addresses_mock.should_receive(:[]).with('public').exactly(4).times.and_return(['2.2.2.2'])
      @addresses_mock.should_receive(:[]).with('private').twice.and_return(['192.168.1.10'])
      @new_rackspace_server.should_receive(:addresses).exactly(6).times.and_return(@addresses_mock)
      @new_rackspace_server.should_receive(:password).exactly(3).times.and_return('super_secret')
      @new_rackspace_server.should_receive(:wait_for)
      @new_rackspace_server.stub!(:save)
      @bootstrap_mock.should_receive(:name_args=).with(['2.2.2.2'])
      @bootstrap_config = {}
      @bootstrap_mock.should_receive(:config).at_least(1).and_return(@bootstrap_config)
      @bootstrap_mock.should_receive(:run)
    end

    describe "with no arguments" do
      it "should create the server with the defaults" do
        @rackspace_servers.should_receive(:create).and_return(@new_rackspace_server)

        @new_rackspace_server.should_receive(:id).exactly(3).times.and_return(105)
        @new_rackspace_server.should_receive(:flavor_id).twice.and_return(1)
        @new_rackspace_server.should_receive(:image_id).twice.and_return(14632)
        @new_rackspace_server.should_receive(:name).twice.and_return('wtf')
        Chef::Knife::Bootstrap.should_receive(:new).and_return(@bootstrap_mock)
        @knife.run
        @stdout.string.should match(Regexp.escape("#{@h.color('Requesting server', :magenta)}"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Instance ID', :cyan)}: 105"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Name', :cyan)}: wtf"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Flavor', :cyan)}: 1"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Image', :cyan)}: 14632"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Public IP Address', :cyan)}: 2.2.2.2"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Private IP Address', :cyan)}: 192.168.1.10"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Password', :cyan)}: super_secret"))
      end
    end

    describe "with setting the flavor (-f or --flavor), image (-i or --image), and server name (-N or --server-name)" do
      it "should create the server using the info supplied" do
        @knife.config[:flavor] = 10
        @knife.config[:image] = 15876
        @knife.config[:server_name] = 'web01'
        @rackspace_servers.should_receive(:create).with(:name => 'web01', :image_id => 15876, :flavor_id => 10).and_return(@new_rackspace_server)
        @new_rackspace_server.should_receive(:flavor_id).twice.and_return(10)
        @new_rackspace_server.should_receive(:image_id).twice.and_return(15876)
        @new_rackspace_server.should_receive(:name).twice.and_return('web01')
        Chef::Knife::Bootstrap.should_receive(:new).and_return(@bootstrap_mock)
        @knife.run
        @stdout.string.should match(Regexp.escape("#{@h.color('Requesting server', :magenta)}"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Name', :cyan)}: web01"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Flavor', :cyan)}: 10"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Image', :cyan)}: 15876"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Public IP Address', :cyan)}: 2.2.2.2"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Private IP Address', :cyan)}: 192.168.1.10"))
        @stdout.string.should match(Regexp.escape("#{@h.color('Password', :cyan)}: super_secret"))
      end
    end

  end
end
