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

describe Chef::Knife::ConfigureClient do
  before(:each) do
    @knife = Chef::Knife::ConfigureClient.new
    @out = StringIO.new
    @knife.stub!(:stdout).and_return(@out)
  end

  describe "run" do
    describe "with a directory" do
      before(:each) do
        @knife.name_args = [ "/etc/my_chef_config_dir" ]
        Chef::Config[:chef_server_url] = 'https://mychefserver.example.com'
        Chef::Config[:validation_client_name] = 'chef-validator'
        Chef::Config[:validation_key] = '/etc/my_chef_config_dir/validation.pem'
      end

      it "should write out the config.rb and validation.pem" do
        FileUtils.should_receive(:mkdir_p).with('/etc/my_chef_config_dir').and_return(true)
        config_file_mock = mock()
        config_file_mock.should_receive(:puts).with('log_level        :info')
        config_file_mock.should_receive(:puts).with('log_location     STDOUT')
        config_file_mock.should_receive(:puts).with("chef_server_url  'https://mychefserver.example.com'")
        config_file_mock.should_receive(:puts).with("validation_client_name 'chef-validator'")
        File.should_receive(:open).with('/etc/my_chef_config_dir/client.rb', 'w').and_yield(config_file_mock)
        validation_pem_mock = mock()
        validation_pem_mock.should_receive(:puts).with('MY VALIDATION KEY')
        IO.should_receive(:read).with('/etc/my_chef_config_dir/validation.pem').and_return('MY VALIDATION KEY')
        File.should_receive(:open).with('/etc/my_chef_config_dir/validation.pem', 'w').and_yield(validation_pem_mock)
        @knife.run
      end
    end

    describe "without a directory argument" do
      it "should not show the client" do
        lambda {
          @knife.should_receive(:show_usage)
          Chef::Log.should_receive(:fatal).with("You must provide the directory to put the files in").and_return(true)
          @knife.run 
        }.should raise_error(SystemExit) { |e| e.status.should == 1 }
      end
    end

  end
end