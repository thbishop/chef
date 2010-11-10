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

describe Chef::Knife::Ec2ServerDelete do

  before(:each) do
    @knife = Chef::Knife::Ec2ServerDelete.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @knife.stub!(:puts)
    @knife.stub!(:print)

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger

    @ec2_connection = mock()
    @ec2_servers = mock()
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    describe "when providing" do
      before(:each) do
        @server_1_mock = mock()
        @server_1_attribs = { :id => 'i-39382318',
          :flavor_id => 'm1.small',
          :image_id => 'ami-47241231',
          :availability_zone => 'us-west-1',
          :key_name => 'my_ssh_key',
          :groups => ['group1', 'group2'],
          :dns_name => 'ec2-75.101.253.10.compute-1.amazonaws.com',
          :ip_address => '75.101.253.10',
          :private_dns_name => 'ip-10-251-75-20.ec2.internal',
          :private_ip_address => '10.251.75.20'
        }

        @server_1_attribs.each_pair do |attrib, value|
          @server_1_mock.should_receive(attrib).and_return(value)
        end

        @knife.name_args = ['i-39382318']
        Fog::AWS::EC2.should_receive(:new).and_return(@ec2_connection)
        @ec2_connection.should_receive(:servers).and_return(@ec2_servers)
      end

      describe "one instance id" do
        it "should delete the instance when we confirm to do so" do
          @ec2_servers.should_receive(:get).with('i-39382318').and_return(@server_1_mock)
          @server_1_mock.should_receive(:destroy)
          @server_1_mock.should_receive(:id).and_return('i-39382318')
          @knife.should_receive(:confirm).with('Do you really want to delete this server').and_return(true)
          @knife.run
          @log_stringio.string.should match(Regexp.escape('WARN -- : Deleted server i-39382318'))
        end

        it "should not delete the instance when we do not confirm to do so" do
          lambda {
            @ec2_servers.should_receive(:get).with('i-39382318').and_return(@server_1_mock)
            @server_1_mock.should_not_receive(:destroy)
            STDIN.should_receive(:readline).and_return("N\n")
            @knife.run
          }.should raise_error(SystemExit)
          @log_stringio.string.should_not match(Regexp.escape('WARN -- : Deleted server i-39382318'))
        end

      end

      describe "two instance ids" do
        before(:each) do
          @server_2_mock = mock()
          @server_2_attribs = { :id => 'i-47389318',
            :flavor_id => 'm1.small',
            :image_id => 'ami-47241279',
            :availability_zone => 'us-west-1',
            :key_name => 'my_ssh_key_2',
            :groups => ['group1', 'group3'],
            :dns_name => 'ec2-75.101.253.15.compute-1.amazonaws.com',
            :ip_address => '75.101.253.15',
            :private_dns_name => 'ip-10-251-75-25.ec2.internal',
            :private_ip_address => '10.251.75.25'
          }

          @server_2_attribs.each_pair do |attrib, value|
            @server_2_mock.should_receive(attrib).and_return(value)
          end

          @knife.name_args << 'i-47389318'
          @ec2_connection.should_receive(:servers).and_return(@ec2_servers)
        end

        it "should delete both instances when we confirm to do so" do
          { 'i-39382318' => @server_1_mock,
            'i-47389318' => @server_2_mock }.each_pair do |instance_id, server_mock|
            @ec2_servers.should_receive(:get).with(instance_id).and_return(server_mock)
            server_mock.should_receive(:destroy)
            server_mock.should_receive(:id).and_return(instance_id)
          end

          @knife.should_receive(:confirm).with('Do you really want to delete this server').twice.and_return(true)
          @knife.run
          @log_stringio.string.should match(Regexp.escape('WARN -- : Deleted server i-39382318'))
          @log_stringio.string.should match(Regexp.escape('WARN -- : Deleted server i-47389318'))
        end
      end

    end

  end
end
