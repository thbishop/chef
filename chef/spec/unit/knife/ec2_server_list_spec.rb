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

describe Chef::Knife::Ec2ServerList do

  def set_attribute_expectations(mock_obj, attribs, times=1)
    attribs.each_pair do |attrib, value|
      mock_obj.should_receive(attrib).exactly(times).times.and_return(value)
    end
  end

  def stdout_should_include_all_of(strings)
    strings.each do |string|
      @stdout.string.should match(Regexp.escape(string))
    end
  end

  def stdout_should_not_include_any_of(strings)
    strings.each do |string|
      @stdout.string.should_not match(Regexp.escape(string))
    end
  end

  def values_as_strings(attribs, separator=', ')
    string_values = []
    attribs.values.each do |value|
      if value.is_a? Array
        string_values << value.join(separator)
      else
        string_values << value
      end
    end

    return string_values
  end

  before(:each) do
    @knife = Chef::Knife::Ec2ServerList.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @knife.stub!(:puts).and_return(@stdout)

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
    before(:each) do
      Fog::AWS::EC2.should_receive(:new).and_return(@ec2_connection)
      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)
    end

    describe "when there" do
      before(:each) do
        @server_1_mock = mock()
        @server_1_core_attribs = { :id => 'i-39382318',
          :groups => ['group1', 'group2'],
          :state => 'running'
        }

        set_attribute_expectations(@server_1_mock, @server_1_core_attribs)

        @server_1_additional_attribs = { :flavor_id => 'm1.small',
          :image_id => 'ami-47241231',
          :ip_address => '75.101.253.10',
          :private_ip_address => '10.251.75.20'
        }
      end

      describe "is one server" do
        it "should list all of its attributes" do
          set_attribute_expectations(@server_1_mock, @server_1_additional_attribs, 2)
          @ec2_servers.should_receive(:all).and_return([@server_1_mock])
          @knife.run

          stdout_should_include_all_of(values_as_strings((@server_1_core_attribs.merge(@server_1_additional_attribs))))
        end

        it "should list only the known attributes" do
          orig_additional_attribs = @server_1_additional_attribs.dup
          @server_1_additional_attribs.keys.each do |key|
            @server_1_additional_attribs[key] = nil
          end

          set_attribute_expectations(@server_1_mock, @server_1_additional_attribs)
          @ec2_servers.should_receive(:all).and_return([@server_1_mock])
          @knife.run

          stdout_should_include_all_of(values_as_strings(@server_1_core_attribs))
          stdout_should_not_include_any_of(orig_additional_attribs.values)
        end
      end

      describe "there are two servers" do
        before(:each) do
          @server_2_mock = mock()
          @server_2_core_attribs = { :id => 'i-49382318',
            :groups => ['group2', 'group3'],
            :state => 'stopped'
          }

          set_attribute_expectations(@server_2_mock, @server_2_core_attribs)

          @server_2_additional_attribs = { :flavor_id => 'm1.small',
            :image_id => 'ami-47241231',
            :ip_address => '75.101.253.20',
            :private_ip_address => '10.251.75.30'
          }
        end

        it "should list all attributes for both of them" do
          { @server_1_mock => @server_1_additional_attribs, 
            @server_2_mock => @server_2_additional_attribs
          }.each_pair do |mock, attribs|
            set_attribute_expectations(mock, attribs, 2)
          end

          @ec2_servers.should_receive(:all).and_return([@server_1_mock, @server_2_mock])
          @knife.run

          
          [ @server_1_core_attribs.merge(@server_1_additional_attribs),
            @server_2_core_attribs.merge(@server_2_additional_attribs)
          ].each do |attribs|
            stdout_should_include_all_of(values_as_strings(attribs))
          end
        end
      end

    end
  end
end
