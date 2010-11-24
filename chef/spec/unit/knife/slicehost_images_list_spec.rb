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

describe Chef::Knife::SlicehostImagesList do
  before(:each) do
    @knife = Chef::Knife::SlicehostImagesList.new

    @stdout = StringIO.new
    $stdout = @stdout
    @knife.stub!(:stdout).and_return(@stdout)

    @slicehost_mock = mock()
    Chef::Config[:knife][:slicehost_password] = 'my-passwd'

    @image_1 = mock()
    @image_1.stub!(:id).and_return(15)
    @image_1.stub!(:name).and_return('centos-5u5')
    @image_2 = mock()
    @image_2.stub!(:id).and_return(20)
    @image_2.stub!(:name).and_return('ubuntu-10.04')
  end

  describe "run" do

    it "should list the images" do
      Fog::Slicehost.should_receive(:new).with(:slicehost_password => 'my-passwd').and_return(@slicehost_mock)
      @slicehost_mock.stub!(:images).and_return([@image_1, @image_2])
      @knife.run
      @stdout.string.should match(/15.+centos-5u5/)
      @stdout.string.should match(/20.+ubuntu-10\.04/)
    end

  end
end
