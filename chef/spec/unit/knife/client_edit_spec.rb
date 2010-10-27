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

describe Chef::Knife::ClientEdit do
  before(:each) do
    @knife = Chef::Knife::ClientEdit.new
  end

  describe "run" do
    describe "when a client name is provided" do
      before(:each) do
        @knife.name_args = [ "adam" ]
      end

      it "should edit the client" do
        @knife.name_args = [ "adam" ]
        @knife.should_receive(:edit_object).with(Chef::ApiClient, "adam")
        @knife.run
      end
    end

    describe "when a client name is not provided" do
      it "should not edit the client" do
        lambda {
          @knife.should_receive(:show_usage)
          Chef::Log.should_receive(:fatal).with("You must specify a client name").and_return(true)
          @knife.run 
        }.should raise_error(SystemExit) { |e| e.status.should == 1 }
      end
    end
  end
end