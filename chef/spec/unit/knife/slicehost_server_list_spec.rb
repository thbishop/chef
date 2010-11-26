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

describe Chef::Knife::SlicehostServerList do
  before(:each) do
    @knife = Chef::Knife::SlicehostServerList.new

    @stdout = StringIO.new
    $stdout = @stdout

    @slicehost_mock = mock()
    Chef::Config[:knife][:slicehost_password] = 'my-passwd'

    @server_1= mock()
    @server_1.stub!(:id).and_return(15)
    @server_1.stub!(:name).and_return('web01')
    @server_1.stub!(:addresses).and_return(['73.21.3.54', '192.168.1.10'])
    @server_1.stub!(:image_id).and_return(15)
    @server_1.stub!(:flavor_id).and_return(1)
    @server_2 = mock()
    @server_2.stub!(:id).and_return(49)
    @server_2.stub!(:name).and_return('app01')
    @server_2.stub!(:addresses).and_return(['73.21.6.87', '192.168.2.50'])
    @server_2.stub!(:image_id).and_return(29)
    @server_2.stub!(:flavor_id).and_return(20)
    @servers = [@server_1, @server_2]

    @image_1 = mock()
    @image_1.stub!(:id).and_return(15)
    @image_1.stub!(:name).and_return('centos-5u5')
    @image_2 = mock()
    @image_2.stub!(:id).and_return(29)
    @image_2.stub!(:name).and_return('ubuntu-10.04')
    @images = [@image_1, @image_2]

    @flavor = mock()
    @flavor_1.stub!(:id).and_return(1)
    @flavor_1.stub!(:name).and_return('256 slice')
    @flavor_2 = mock()
    @flavor_2.stub!(:id).and_return(20)
    @flavor_2.stub!(:name).and_return('100GB slice')
    @flavors = [@flavor_1, @flavor_2]

    @slicehost_mock.stub!(:images).and_return(@images)
    @slicehost_mock.stub!(:flavors).and_return(@flavors)
    @slicehost_mock.stub!(:servers).and_return(@servers)
  end

  describe "run" do
    before(:each) do
      Fog::Slicehost.should_receive(:new).with(:slicehost_password => 'my-passwd').and_return(@slicehost_mock)
    end

    it "should list the servers and related info" do
      @knife.run
      @stdout.string.should match(/15.+web01.+192\.168\.1\.10.+73\.21\.3\.54.+centos-5u5.+256 slice.+49.+app01.+192\.168\.2\.50.+73\.21\.6\.87.+ubuntu-10\.04.+100GB slice/m)
    end
  end
end
