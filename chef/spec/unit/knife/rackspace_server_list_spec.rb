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

describe Chef::Knife::RackspaceServerList do
  before(:each) do
    @knife = Chef::Knife::RackspaceServerList.new

    @stdout = StringIO.new
    $stdout = @stdout

    @rackspace_connection = mock()
    @rackspace_servers = mock()

    @existing_rackspace_server_1 = mock()
    @existing_rackspace_server_1.stub!(:id).and_return(2736)
    @existing_rackspace_server_1.stub!(:name).and_return('web01')
    @existing_rackspace_server_1.stub!(:flavor_id).and_return(347)
    @address_mock_1 = mock()
    @address_mock_1.stub!(:[]).with('public').and_return(['2.3.4.5'])
    @address_mock_1.stub!(:[]).with('private').and_return(['192.168.1.20'])
    @existing_rackspace_server_1.stub!(:addresses).and_return(@address_mock_1)

    @existing_rackspace_server_2 = mock()
    @existing_rackspace_server_2.stub!(:id).and_return(7564)
    @existing_rackspace_server_2.stub!(:name).and_return('app01')
    @existing_rackspace_server_2.stub!(:flavor_id).and_return(674)
    @address_mock_2 = mock()
    @address_mock_2.stub!(:[]).with('public').and_return(['4.5.6.7'])
    @address_mock_2.stub!(:[]).with('private').and_return(['192.168.1.30'])
    @existing_rackspace_server_2.stub!(:addresses).and_return(@address_mock_2)

    @servers = [@existing_rackspace_server_1, @existing_rackspace_server_2]
    @rackspace_servers.should_receive(:all).and_return(@servers)
    @rackspace_connection.should_receive(:servers).and_return(@rackspace_servers)

    Chef::Config[:knife][:rackspace_api_key] = 'my-api-key'
    Chef::Config[:knife][:rackspace_api_username] = 'my-api-username'
    Fog::Rackspace::Servers.should_receive(:new).and_return(@rackspace_connection)
  end

  describe "run" do
    it "should output the output the information about the servers" do
      @knife.run
      @servers.each do |server|
        @stdout.string.should match(Regexp.escape(server.id.to_s))
        @stdout.string.should match(Regexp.escape(server.name))
        @stdout.string.should match(Regexp.escape(server.flavor_id.to_s))
        @stdout.string.should match(Regexp.escape(server.addresses['public'].first))
        @stdout.string.should match(Regexp.escape(server.addresses['private'].first))
      end
    end
  end

end
