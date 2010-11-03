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

describe Chef::Knife::CookbookSiteSearch do

  before(:each) do
    @knife = Chef::Knife::CookbookSiteSearch.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
  end

  describe "run" do
    before(:each) do
      @cookbook_list_query_boo = { 'total' => 2,
                                   'start' => 0,
                                   'items' => [ {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/boost', 'cookbook_name' => 'boost'},
                                                {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/bootstrap', 'cookbook_name' => 'bootstrap'} ]
      }

      @cookbook_list_1 = { 'total' => 20, 
                           'start' => 0,
                           'items' => [ {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/accounts', 'cookbook_name' => 'accounts'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/activemq', 'cookbook_name' => 'activemq'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/ad-likewise', 'cookbook_name' => 'ad-likewise'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/apache2', 'cookbook_name' => 'apache2'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/apcupsd', 'cookbook_name' => 'apcupsd'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/apparmor', 'cookbook_name' => 'apparmor'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/application', 'cookbook_name' => 'application'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/apt', 'cookbook_name' => 'apt'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/aws', 'cookbook_name' => 'aws'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/bluepill', 'cookbook_name' => 'bluepill'} ]
      }

      @cookbook_list_2 = { 'total' => 20, 
                           'start' => 10,
                           'items' => [ {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/cron', 'cookbook_name' => 'cron'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/bundler', 'cookbook_name' => 'bundler'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/cakephp', 'cookbook_name' => 'cakephp'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/capistrano', 'cookbook_name' => 'capistrano'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/chef', 'cookbook_name' => 'chef'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/cloudkick', 'cookbook_name' => 'cloudkick'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/cobbler', 'cookbook_name' => 'cobbler'},
                                        {'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/couchdb', 'cookbook_name' => 'couchdb'} ]
      }

      @cookbook_list_2['items'].concat @cookbook_list_query_boo['items']
    end

    describe "with no input" do
      it "should query the cookbook site for all cookbooks" do
        @rest.should_receive(:get_rest).with('http://cookbooks.opscode.com/api/v1/search?q=&items=10&start=0').and_return(@cookbook_list_1)
        @rest.should_receive(:get_rest).with('http://cookbooks.opscode.com/api/v1/search?q=&items=10&start=10').and_return(@cookbook_list_2)
        @knife.run

        [@cookbook_list_1, @cookbook_list_2].each do |cookbook_list|
          cookbook_list['items'].each do |item|
            @stdout.string.should include(item['cookbook_name'])
            @stdout.string.should include(item['cookbook'])
          end
        end

      end
    end

    describe "when providing input for the query" do
      it "should query the cookbook site with the input" do
        @knife.name_args = ['boo']
        @rest.should_receive(:get_rest).with('http://cookbooks.opscode.com/api/v1/search?q=boo&items=10&start=0').and_return(@cookbook_list_query_boo)
        @knife.run

        @cookbook_list_query_boo['items'].each do |item|
          @stdout.string.should include(item['cookbook'])
          @stdout.string.should include(item['cookbook'])
        end

      end
    end

  end
end