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

describe Chef::Knife::Exec do
  before(:each) do
    @knife = Chef::Knife::Exec.new
  end

  describe "run" do
    before(:each) do
      @context_mock = mock()
      @knife.stub!(:get_new_obj).and_return(@context_mock)
      Shef::Extensions.stub!(:extend_context_object)
      @knife.name_args = []
    end

    describe "without a script" do
      it "should read from STDIN" do
        STDIN.should_receive(:read).and_return('puts "hello from stdin"')
        @context_mock.should_receive(:instance_eval).with('puts "hello from stdin"', "STDIN", 0)
        @knife.run
      end
    end

    describe "with scripts" do
      it "should eval all of them" do
        scripts = ['/var/tmp/my_script.rb', '/var/tmp/script_2.rb']
        @knife.name_args = scripts

        scripts.each do |script|
          File.should_receive(:expand_path).and_return(script)
          IO.should_receive(:read).with(script).and_return("puts 'hello #{script}'")
          @context_mock.should_receive(:instance_eval).with("puts 'hello #{script}'", script, 0)
        end

        @knife.run
      end
    end

    describe "with -E or --exec" do 
      it "should eval the provided code" do
        @knife.config[:exec] = 'puts "hello from exec"'
        @context_mock.should_receive(:instance_eval).with('puts "hello from exec"', '-E Argument', 0)
        @knife.run
      end
    end

  end
end
