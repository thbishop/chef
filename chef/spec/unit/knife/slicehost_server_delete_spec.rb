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

describe Chef::Knife::SlicehostServerDelete do
  before(:each) do
    @knife = Chef::Knife::SlicehostServerDelete.new

    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger

    @slicehost_mock = mock()
    Chef::Config[:knife][:slicehost_password] = 'my-passwd'

    @response_mock = mock()

    @server_1= mock()
    @server_1.stub!(:id).and_return(15)
    @server_1.stub!(:name).and_return('web01')
    @server_2 = mock()
    @server_2.stub!(:id).and_return(49)
    @server_2.stub!(:name).and_return('app01')
    @servers = [@server_1, @server_2]

    @slicehost_mock.stub!(:servers).and_return(@servers)
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    before(:each) do
      Fog::Slicehost.should_receive(:new).with(:slicehost_password => 'my-passwd').and_return(@slicehost_mock)

      @response_headers= { 'status' => '200 OK' }
      @response_mock.stub!(:headers).and_return(@response_headers)
    end

    it "should log a warning and return if the slice name can't be found" do
      @knife.name_args = ['db01']
      @knife.run
      @log_stringio.string.should match(Regexp.escape("WARN -- : I can't find a slice named db01"))
    end

    it "should delete the slice when confirmed to do so" do
      @knife.name_args = ['web01']
      @knife.should_receive(:confirm).with('Do you really want to delete server ID 15 named web01').and_return(true)
      @slicehost_mock.should_receive(:delete_slice).with(15).and_return(@response_mock)
      @knife.run
      @log_stringio.string.should match(Regexp.escape('WARN -- : Deleted server 15 named web01'))
    end

    it "should log a warning if an exception is encountered when deletng the slice" do
      @knife.name_args = ['web01']
      @knife.should_receive(:confirm).with('Do you really want to delete server ID 15 named web01').and_return(true)
      @slicehost_mock.should_receive(:delete_slice).and_raise(Excon::Errors::UnprocessableEntity)
      @knife.run
      @log_stringio.string.should match(Regexp.escape('WARN -- : There was a problem deleting web01, check your slice manager'))
    end

    it "should not delete the slice when we do not confirm to do so" do
      lambda{
        @knife.name_args = ['web01']
        @knife.stub!(:stdin).and_return(StringIO.new("N\n"))
        @slicehost_mock.should_not_receive(:delete_slice)
        @knife.run
      }.should raise_error(SystemExit)
    end

  end
end
