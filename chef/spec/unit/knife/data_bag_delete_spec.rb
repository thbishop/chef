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

describe Chef::Knife::DataBagDelete do

  before(:each) do
    @knife = Chef::Knife::DataBagDelete.new
    @stdout = StringIO.new
    @knife.stub!(:stdout).and_return(@stdout)

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger

    @rest = mock("Chef::REST")
    @knife.stub!(:rest).and_return(@rest)
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    describe "when no arguments are provided" do
      it "should log an error and exit" do
        lambda {
        @knife.should_receive(:show_usage)
        @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 1 }
        @log_stringio.string.should match(Regexp.escape('FATAL -- : You must specify at least a data bag name'))
      end
    end

    describe "when providing the data bag name" do
      before(:each) do
        @knife.name_args = ['admins']
      end

      it "should delete the data bag" do
        @knife.should_receive(:delete_object).with(Chef::DataBag, 'admins', 'data_bag').and_yield
        @rest.should_receive(:delete_rest).with('data/admins')
        @knife.run
      end

      describe "and when providing an item in the data bag" do
        before(:each) do
          @knife.name_args << 'bob'
        end

        it "should delete the specified item" do
        @knife.should_receive(:delete_object).with(Chef::DataBagItem, 'bob', 'data_bag_item').and_yield
        @rest.should_receive(:delete_rest).with('data/admins/bob')
        @knife.run
        end
      end

    end
  end
end
