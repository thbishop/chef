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

describe Chef::Knife::CookbookDelete do
  before(:each) do
    @knife = Chef::Knife::CookbookDelete.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)
    @rest = mock("Chef::REST")

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    describe "with a cookbook name but without a version" do
      before(:each) do
        @knife.name_args = ["pizza"]
      end

      describe "when there is only one version of the cookbook" do
        before(:each) do
          @cookbook_data = { 'pizza' => [ '0.0.1'] }
        end

        it "should delete the specified cookbook version" do
          @rest.should_receive(:get_rest).with('cookbooks/pizza').and_return(@cookbook_data)
          @rest.should_receive(:delete_rest).with('cookbooks/pizza/0.0.1').and_return(true)
          @knife.should_receive(:delete_object).and_yield
          @knife.stub!(:rest).and_return(@rest)
          @knife.run
        end

        describe "and we specify -p or --purge" do
          it "should purge the all of files for the cookbooks" do
            @knife.config[:purge] = true
            @knife.should_receive(:confirm).with('Files that are common to multiple cookbooks are shared, so purging the files may disable other cookbooks. Are you sure you want to purge files instead of just deleting the cookbook').and_return(true)
            @knife.should_receive(:delete_object).and_yield
            @rest.should_receive(:get_rest).with('cookbooks/pizza').and_return(@cookbook_data)
            @knife.stub!(:rest).and_return(@rest)
            @rest.should_receive(:delete_rest).with('cookbooks/pizza/0.0.1?purge=true').and_return(true)
            @knife.run
          end
        end

        it "should handle an exception (other than a 404) when querying for our cookbook" do
          lambda {
            @rest.should_receive(:get_rest).with('cookbooks/pizza').and_raise(Timeout::Error)
            @knife.stub!(:rest).and_return(@rest)
            @knife.run
          }.should raise_error(Timeout::Error)
        end
      end

      describe "when there are multiple versions of the the cookbook" do
        before(:each) do
          @cookbook_data = { 'pizza' => [ '0.0.1', '0.0.2'] }
          @rest.should_receive(:get_rest).with('cookbooks/pizza').and_return(@cookbook_data)
          @version_to_delete_prompt = /Which version\(s\) do you want to delete\?\n1\. pizza 0\.0\.1\n2\. pizza 0\.0\.2\n3\. All versions\n\n/
        end

        describe "and we don't specify a version to delete when prompted" do
          it "should log the error and exit" do
            lambda {
              STDIN.stub!(:readline).and_return("\n")
              @rest.should_not_receive(:delete_rest)
              @knife.stub!(:rest).and_return(@rest)
              @knife.run
            }.should raise_error(SystemExit) { |e| e.status.should == 1 }
              @log_stringio.string.should match(Regexp.escape("ERROR -- : No versions specified, exiting"))
          end
        end

        describe "and we specify an invalid version to delete when prompted" do
          it "should log the error and skip deleting it" do
            STDIN.stub!(:readline).and_return("foo\n")
            @rest.should_not_receive(:delete_rest)
            @knife.stub!(:rest).and_return(@rest)
            @knife.run
            @stdout.string.should match(@version_to_delete_prompt)
            @log_stringio.string.should match(Regexp.escape("ERROR -- : foo is not a valid choice, skipping it"))
          end
        end

        scenarios_and_responses = { 'delete each of them' => "1, 2\n",
                                    'delete all of them' => "3\n",
                                    'delete all of them and a specific version' => "1, 3\n" }

        scenarios_and_responses.each_pair { |message, response|
          describe "and we specify to #{message} when prompted" do
            it "should #{message}" do
              STDIN.should_receive(:readline).and_return("1, 2\n")
              @rest.should_receive(:delete_rest).with('cookbooks/pizza/0.0.1').and_return(true)
              @rest.should_receive(:delete_rest).with('cookbooks/pizza/0.0.2').and_return(true)
              @knife.stub!(:rest).and_return(@rest)
              @knife.run
              @stdout.string.should match(@version_to_delete_prompt)
              @log_stringio.string.should match(Regexp.escape("INFO -- : Deleted cookbook[pizza][0.0.1]"))
              @log_stringio.string.should match(Regexp.escape("INFO -- : Deleted cookbook[pizza][0.0.2]"))
            end
          end
        }

        describe "and we specify -a or --all" do
          it "should delete all of the cookbooks" do
            @knife.config[:all] = true
            @knife.stub!(:rest).and_return(@rest)
            @rest.should_receive(:delete_rest).with('cookbooks/pizza/0.0.1').and_return(true)
            @rest.should_receive(:delete_rest).with('cookbooks/pizza/0.0.2').and_return(true)
            @knife.should_receive(:confirm).with('Do you really want to delete all versions of pizza').and_return(true)
            @knife.run
            @log_stringio.string.should match(Regexp.escape("INFO -- : Deleted cookbook[pizza][0.0.1]"))
            @log_stringio.string.should match(Regexp.escape("INFO -- : Deleted cookbook[pizza][0.0.2]"))
          end
        end

      end
    end

    describe "when the cookbook name isn't valid" do
      it "should log delete the specified cookbook version" do
        lambda {
          @knife.name_args = ["not_valid"]
          http_404_exception = Net::HTTPServerException.new('404', 'HTTPNotFound')
          @rest.should_receive(:get_rest).with('cookbooks/not_valid').and_raise(http_404_exception)
          @knife.stub!(:rest).and_return(@rest)
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 1 }
          @log_stringio.string.should match(Regexp.escape("ERROR -- : Cannot find a cookbook named not_valid to delete"))
      end
    end

    describe "with a valid cookbook name and valid version" do
      before(:each) do
        @knife.name_args = ['pizza', '0.0.1']
      end

      it "should delete the specified version of the cookbook" do
        @rest.should_not_receive(:get_rest)
        @rest.should_receive(:delete_rest).with('cookbooks/pizza/0.0.1').and_return(true)
        @knife.should_receive(:delete_object).and_yield
        @knife.stub!(:rest).and_return(@rest)
        @knife.run
      end
    end

    describe "without a cookbook name" do
      it "should show the usage, log the error, and exit" do
        @knife.name_args = []
        lambda {
          @knife.should_receive(:show_usage)
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 1}
        @log_stringio.string.should match(Regexp.escape("FATAL -- : You must provide the name of the cookbook to delete"))
      end
    end

  end
end
