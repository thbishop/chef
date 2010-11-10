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

describe Chef::Knife::Ec2InstanceData do

  before(:each) do
    @knife = Chef::Knife::Ec2InstanceData.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    before(:each) do
      Chef::Config[:chef_server_url] = 'https://chef-server.example.com'
      Chef::Config[:validation_client_name] = 'validation_client'
      Chef::Config[:validation_key] = '/etc/chef/client.pem'
      IO.should_receive(:read).with(Chef::Config[:validation_key]).and_return('super_secret_key')
      @instance_data = { 'chef_server' => 'https://chef-server.example.com',
                         'validation_client_name' => 'validation_client',
                         'validation_key' => 'super_secret_key',
                         'attributes' => { 'run_list' => [] }
      }
    end

    it "should output the data" do
      @knife.should_not_receive(:edit_data)
      @knife.should_receive(:output).with(@instance_data)
      @knife.run
    end

    it "should edit and then output data with -e or --edit" do
      @knife.config[:edit] = true
      @knife.should_receive(:edit_data).with(@instance_data).and_return(@instance_data)
      @knife.should_receive(:output).with(@instance_data)
      @knife.run
    end

    describe "when providing multiple run list items" do
      before(:each) do
        @knife.name_args = ['pizza', 'dough', 'cheese']
        @instance_data['attributes']['run_list'] << 'pizza' << 'dough' << 'cheese'
      end

      it "should include the run list items in the output" do
        @knife.should_not_receive(:edit_data)
        @knife.should_receive(:output).with(@instance_data)
        @knife.run
      end
    end

  end
end
