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

describe Chef::Knife::ClientShow do
  before(:each) do
    @knife = Chef::Knife::ClientShow.new
    @out = StringIO.new
    @knife.stub!(:stdout).and_return(@out)
  end

  describe "run" do
    describe "with a client name" do
      before(:each) do
        @knife.name_args = [ "adam" ]
        @client_data = { 'name' => 'chef-client1.example.com', 'public_key' => 'MY PUBLIC KEY DATA'}
        Chef::ApiClient.should_receive(:load).and_return(@client_data)
      end

      describe "without any arguments" do
        it "should show the client" do
          @knife.run
          @out.string.should match(/.+"public_key": "MY PUBLIC KEY DATA"/)
        end
      end

      describe "with an attribute argument" do
        it "should only show that attribute" do
          @knife.config[:format] = 'text'
          @knife.config[:attribute] = 'public_key'
          @knife.run
          @out.string.should == "MY PUBLIC KEY DATA\n"
        end
      end
    end

    describe "without a client name" do
      it "should not show the client" do
        lambda {
          @knife.should_receive(:show_usage)
          Chef::Log.should_receive(:fatal).with("You must specify a client name").and_return(true)
          @knife.run 
        }.should raise_error(SystemExit) { |e| e.status.should == 1 }
      end
    end
  end

end