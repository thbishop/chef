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

describe Chef::Knife::RoleShow do
  before(:each) do
    @knife = Chef::Knife::RoleShow.new

    @log_stringio = StringIO.new
    @logger = Logger.new(@log_stringio)
    @original_chef_logger = Chef::Log.logger
    Chef::Log.logger = @logger
  end

  after do
    Chef::Log.logger = @original_chef_logger
  end

  describe "run" do
    describe "without a role" do
      it "should show the usage, log an error and exit" do
        lambda {
          @knife.should_receive(:show_usage)
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 1}
        @log_stringio.string.should match(Regexp.escape('FATAL -- : You must specify a role name'))
      end
    end

    describe "with a role" do
      before(:each) do
        @knife.name_args = ['web']
      end

      it "should show the role" do
        @role = Chef::Role.new()
        Chef::Role.should_receive(:load).with('web').and_return(@role)
        @knife.should_receive(:output).with(@role)
        @knife.run
      end
    end
  end

end
