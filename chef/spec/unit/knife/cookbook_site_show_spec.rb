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

describe Chef::Knife::CookbookSiteShow do

  before(:each) do
    @knife = Chef::Knife::CookbookSiteShow.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
  end

  describe "run" do
    describe "when providing a cookbook name" do
      before(:each) do
        @knife.name_args = ['pizza']
        @cookbook_data = { 'name' => 'pizza',
                           'maintainer' => 'tony',
                           'latest_version' => 'http://cookbooks.opscode.com/api/v1/cookbooks/pizza/versions/0_1_3',
                           'versions' => [ "http://cookbooks.opscode.com/api/v1/cookbooks/pizza/versions/0_1_3",
                                           "http://cookbooks.opscode.com/api/v1/cookbooks/pizza/versions/0_1_2",
                                           "http://cookbooks.opscode.com/api/v1/cookbooks/pizza/versions/0_1_1" ]
        }
      end

      it "should output the cookbook data and all known versions" do
        @rest.should_receive(:get_rest).with('http://cookbooks.opscode.com/api/v1/cookbooks/pizza').and_return(@cookbook_data)
        @knife.run

        ['name', 'maintainer', 'latest_version'].each do |item|
          @stdout.string.should include(@cookbook_data[item])
        end

        @cookbook_data['versions'].each do |version_uri|
          @stdout.string.should include(version_uri)
        end
      end

      describe "and a version" do
        before(:each) do
          @knife.name_args << '0.1.2'
          @cookbook_0_1_2_data = { 'license' => 'Apache 2.0',
                                   'version' => '0.1.2',
                                   'file' => 'http://s3.amazonaws.com/opscode/cookbooks/tarballs/310/original/pizza-0_1_2.tar.gz',
                                   'cookbook' => 'http://cookbooks.opscode.com/api/v1/cookbooks/pizza'
          }
        end

        it "should output the data for the specific version of the cookbook" do
          @rest.should_receive(:get_rest).with('http://cookbooks.opscode.com/api/v1/cookbooks/pizza/versions/0_1_2').and_return(@cookbook_0_1_2_data)
          @knife.run

          ['license', 'version', 'file', 'cookbook'].each do |item|
            @stdout.string.should include(@cookbook_0_1_2_data[item])
          end
        end

      end
    end

  end
end