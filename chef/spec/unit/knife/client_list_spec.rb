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

describe Chef::Knife::ClientList do
  before(:each) do
    @knife = Chef::Knife::ClientList.new
    @out = StringIO.new
    @knife.stub!(:stdout).and_return(@out)
  end

  describe "run" do
    before(:each) do
      @nodes = { 'node-1.example.com' => 'https://chefserver.example.com/clients/node-1.example.com',
                 'node-2.example.com' => 'https://chefserver.example.com/clients/node-2.example.com' }
    end

    describe "without any arguments" do
      it "should output the client names" do
        Chef::ApiClient.should_receive(:list).and_return(@nodes)
        @knife.run
        @out.string.should match(/.+\"node-1.example.com\",\n\s+\"node-2.example.com\"\n.+/)
      end
    end

    describe "when requesting the 'with-uri' argument" do
      it "should output the client names and their uris" do
        Chef::ApiClient.should_receive(:list).and_return(@nodes)
        @knife.config[:with_uri] = true
        @knife.run
        @out.string.should match(/.+\"node-2.example.com\": "https:\/\/chefserver.example.com\/clients\/node-2.example.com",\n\s+\"node-1.example.com\": "https:\/\/chefserver.example.com\/clients\/node-1.example.com"\n.+/)
      end
    end
  end
end