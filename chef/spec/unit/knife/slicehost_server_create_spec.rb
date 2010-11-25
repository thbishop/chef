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

describe Chef::Knife::SlicehostServerCreate do
  before(:each) do
    @knife = Chef::Knife::SlicehostServerCreate.new

    @knife.initial_sleep_delay = 0

    @stdout = StringIO.new
    $stdout = @stdout
    @knife.stub!(:stdout).and_return(@stdout)

    @slicehost_mock = mock()
    Chef::Config[:knife][:slicehost_password] = 'my-passwd'

    @image_1 = mock()
    @image_1.stub!(:id).and_return(15)
    @image_1.stub!(:name).and_return('centos-5u5')
    @image_2 = mock()
    @image_2.stub!(:id).and_return(49)
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

    @response_mock = mock()
    @host_mock = mock()
  end

  describe "run" do
    before(:each) do
      Fog::Slicehost.should_receive(:new).with(:slicehost_password => 'my-passwd').and_return(@slicehost_mock)

      @response_attribs = { 'name' => 'wtf',
        'flavor-id' => 1,
        'image-id' => 49,
        'addresses' => ['192.168.1.10', '5.4.2.2'],
        'root-password' => 'super-secret-passwd',
        'id' => 5674
      }
      @response_mock.stub!(:body).and_return(@response_attribs)
    end

    describe "without any arguments" do
      before(:each) do
        @slicehost_mock.should_receive(:create_slice).with(1, 49, 'wtf').and_return(@response_mock)
      end

      it "should create the server with the defaults" do
        @host_mock.should_receive(:body).and_return({'status' => 'active'})
        @slicehost_mock.should_receive(:get_slice).with(5674).and_return(@host_mock)
        @knife.run

        [/Name.+wtf/, /Flavor.+256 slice/, /Image.+ubuntu-10\.04/, /Private Address.+192.168.1.10/, /Public Address.+5.4.2.2/, /Password.+super-secret-passwd/].each do |regex|
          @stdout.string.should match(regex)
        end

        @stdout.string.should match(Regexp.escape('Server ready'))
      end

      it "should loop until the host is active" do
        @host_mock.should_receive(:body).twice.and_return({'status' => 'booting'}, {'status' => 'active'})
        @slicehost_mock.should_receive(:get_slice).twice.with(5674).and_return(@host_mock)
        @knife.run

        [/Name.+wtf/, /Flavor.+256 slice/, /Image.+ubuntu-10\.04/, /Private Address.+192.168.1.10/, /Public Address.+5.4.2.2/, /Password.+super-secret-passwd/].each do |regex|
          @stdout.string.should match(regex)
        end

        @stdout.string.should match(Regexp.escape('Server ready'))
      end
    end

    describe "with -f or --flavor" do
      it "should create the server with the flavor provided" do
        @knife.config[:flavor] = 20
        @response_attribs['flavor-id']  = 20
        @slicehost_mock.should_receive(:create_slice).with(20, 49, 'wtf').and_return(@response_mock)
        @host_mock.should_receive(:body).and_return({'status' => 'active'})
        @slicehost_mock.should_receive(:get_slice).with(5674).and_return(@host_mock)
        @knife.run

        [/Name.+wtf/, /Flavor.+100GB slice/, /Image.+ubuntu-10\.04/, /Private Address.+192.168.1.10/, /Public Address.+5.4.2.2/, /Password.+super-secret-passwd/].each do |regex|
          @stdout.string.should match(regex)
        end

        @stdout.string.should match(Regexp.escape('Server ready'))
      end
    end

    describe "with -i or --image" do
      it "should create the server with the flavor provided" do
        @knife.config[:image] = 15
        @response_attribs['image-id']  = 15
        @slicehost_mock.should_receive(:create_slice).with(1, 15, 'wtf').and_return(@response_mock)
        @host_mock.should_receive(:body).and_return({'status' => 'active'})
        @slicehost_mock.should_receive(:get_slice).with(5674).and_return(@host_mock)
        @knife.run

        [/Name.+wtf/, /Flavor.+256 slice/, /Image.+centos-5u5/, /Private Address.+192.168.1.10/, /Public Address.+5.4.2.2/, /Password.+super-secret-passwd/].each do |regex|
          @stdout.string.should match(regex)
        end

        @stdout.string.should match(Regexp.escape('Server ready'))
      end
    end

    describe "with -N or --server-name" do
      it "should create the server with the server name provided" do
        @knife.config[:server_name] = 'web01'
        @response_attribs['name']  = 'web01'
        @slicehost_mock.should_receive(:create_slice).with(1, 49, 'web01').and_return(@response_mock)
        @host_mock.should_receive(:body).and_return({'status' => 'active'})
        @slicehost_mock.should_receive(:get_slice).with(5674).and_return(@host_mock)
        @knife.run

        [/Name.+web01/, /Flavor.+256 slice/, /Image.+ubuntu-10\.04/, /Private Address.+192.168.1.10/, /Public Address.+5.4.2.2/, /Password.+super-secret-passwd/].each do |regex|
          @stdout.string.should match(regex)
        end

        @stdout.string.should match(Regexp.escape('Server ready'))
      end
    end

  end
end
