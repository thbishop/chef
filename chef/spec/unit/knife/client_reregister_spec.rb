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

describe Chef::Knife::ClientReregister do
  before(:each) do
    @knife = Chef::Knife::ClientReregister.new
    @knife.config = {
      :file => nil
    }
    @client = Chef::ApiClient.new
    @client.stub!(:save).and_return({ 'private_key' => '' })
    Chef::ApiClient.stub!(:load).and_return(@client)
  end

  describe "run" do
    describe "when a client name is provided" do
      before(:each) do
        @knife.name_args = [ "adam" ]
      end

      it "should create a new Client" do
        @knife.run
      end

      it "should not set the Client name" do
        @client.should_not_receive(:name).with("adam")
        @knife.run
      end

      it "should save the Client" do
        @client.should_receive(:save).with(true)
        @knife.run
      end

      describe "with -f or --file" do
        it "should write the private key to a file" do
          @knife.config[:file] = "/tmp/monkeypants"
          @client.stub!(:save).and_return({ 'private_key' => "woot" })
          filehandle = mock("Filehandle")
          filehandle.should_receive(:print).with('woot')
          File.should_receive(:open).with("/tmp/monkeypants", "w").and_yield(filehandle)
          @knife.run
        end
      end
    end
  end

  describe "when a client name is not provided" do
    it "should not reregister the client" do
      lambda {
        @knife.should_receive(:show_usage)
        Chef::Log.should_receive(:fatal).with("You must specify a client name").and_return(true)
        @knife.run 
      }.should raise_error(SystemExit) { |e| e.status.should == 1 }
    end
  end

end