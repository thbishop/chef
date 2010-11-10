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

describe Chef::Knife::DataBagFromFile do

  before(:each) do
    @knife = Chef::Knife::DataBagFromFile.new
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
    before(:each) do
      @knife.name_args = ['admins', 'bob']
    end

    it "should update the data bag item" do
      @knife.should_receive(:load_from_file).with(Chef::DataBagItem, 'bob', 'admins').and_return('data bag stuff')
      data_bag_mock = mock()
      data_bag_mock.should_receive(:data_bag).with('admins')
      data_bag_mock.should_receive(:raw_data=).with('data bag stuff')
      data_bag_mock.should_receive(:save)
      Chef::DataBagItem.should_receive(:new).and_return(data_bag_mock)
      @knife.run
      @log_stringio.string.should match(Regexp.escape('INFO -- : Updated data_bag_item[bob]'))
    end

  end
end
