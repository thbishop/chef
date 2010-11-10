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

describe Chef::Knife::DataBagEdit do

  before(:each) do
    @knife = Chef::Knife::DataBagEdit.new
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
    describe "when providing the data bag name" do
      before(:each) do
        @knife.name_args = ['admins']
      end

      it "should log an error and exit" do
        lambda {
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 42 }
        @log_stringio.string.should match(Regexp.escape('FATAL -- : You must supply the data bag and an item to edit!'))
      end

      describe "and when providing the item to edit" do
        before(:each) do
          @knife.name_args << 'bob'
        end

        it "should edit the data bag item" do
          object_mock = mock()
          Chef::DataBagItem.should_receive(:load).with('admins', 'bob').and_return(object_mock)
          output_mock = mock()
          @knife.should_receive(:edit_data).with(object_mock).and_return(output_mock)
          @rest.should_receive(:put_rest).with("data/admins/bob", output_mock)
          @knife.run
          @log_stringio.string.should match(Regexp.escape('Saved data_bag_item[bob]'))
        end

        it "should show the data when -p or --print-after is specified" do
          @knife.config[:print_after] = true
          object_mock = mock()
          Chef::DataBagItem.should_receive(:load).with('admins', 'bob').and_return(object_mock)
          output_mock = mock()
          @knife.should_receive(:edit_data).with(object_mock).and_return(output_mock)
          @rest.should_receive(:put_rest).with("data/admins/bob", output_mock)
          @knife.should_receive(:format_for_display).with(object_mock)
          @knife.should_receive(:output)
          @knife.run
          @log_stringio.string.should match(Regexp.escape('Saved data_bag_item[bob]'))
        end

        describe "and when providing an irrelevant third argument" do
          before(:each) do
            @knife.name_args << 'foo bar'
          end

          it "should log an error and exit" do
            lambda {
              @knife.run
            }.should raise_error(SystemExit) { |e| e.status.should == 42 }
            @log_stringio.string.should match(Regexp.escape('FATAL -- : You must supply the data bag and an item to edit!'))
          end
        end

      end
    end
  end
end


