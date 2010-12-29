#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2010 Thomas Bishop
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

describe Chef::Knife::CookbookList do
  before(:each) do
    @knife = Chef::Knife::CookbookList.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
  end

  describe "run" do
    before(:each) do
      @chef_server_url = 'https://chefserver.example.com'
    end

    describe "without an environment set" do
      before(:each) do
        @cookbooks = { 'foo' => "#{@chef_server_url}/cookbooks/foo/1.0.0",
                       'bar' => "#{@chef_server_url}/cookbooks/bar/2.3.4",
                       'baz' => "#{@chef_server_url}/cookbooks/baz/7.1.8"
        }
        @rest.should_receive(:get_rest).with('/cookbooks/_latest').and_return(@cookbooks)
      end

      describe "without any arguments" do
        it "should output the cookbook names" do
          @knife.run
          @cookbooks.each_pair do |name, uri|
            @stdout.string.should include(name)
            @stdout.string.should_not include(uri)
          end
        end
      end

      describe "with -w or --with-uri" do
        it "should output the cookbook names and their uris with -w or --with-uri" do
          @knife.config[:with_uri] = true
          @knife.run
          @cookbooks.each_pair do |name, uri|
            @stdout.string.should include(name)
            @stdout.string.should include(uri)
          end
        end
      end
    end

    describe "with an environment set" do
      before(:each) do
        Chef::Config[:environment] = 'production'
        @cookbooks = { 'foo' => "#{@chef_server_url}/environments/production/cookbooks/foo/1.0.0",
                       'bar' => "#{@chef_server_url}/environments/production/cookbooks/bar/2.3.4",
                       'baz' => "#{@chef_server_url}/environments/production/cookbooks/baz/7.1.8"
        }
        @rest.should_receive(:get_rest).with('/environments/production/cookbooks').and_return(@cookbooks)
      end

      describe "without any arguments" do
        it "should output the cookbook names" do
          @knife.run
          @cookbooks.each_pair do |name, uri|
            @stdout.string.should include(name)
            @stdout.string.should_not include(uri)
          end
        end
      end
    end

  end
end
