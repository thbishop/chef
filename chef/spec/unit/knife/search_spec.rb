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

describe Chef::Knife::Search do
  before(:each) do
    @knife = Chef::Knife::Search.new

    @stdout = StringIO.new
    $stdout = @stdout
    @knife.stub!(:stdout).and_return(@stdout)

    @node_1 = Chef::Node.new()
    @node_1.name 'web01'
    @run_list = Chef::RunList.new
    @run_list << 'recipe[apache]'
    @run_list << 'recipe[ssl]'
    @node_1.run_list @run_list
    @node_1.automatic_attrs[:platform] = 'ubuntu'
    @node_1.automatic_attrs[:hostname] = 'web01.example.com'

    @node_2 = Chef::Node.new()
    @node_2.name 'app01'
    @run_list = Chef::RunList.new
    @run_list << 'recipe[jdk]'
    @run_list << 'recipe[jboss]'
    @node_2.run_list @run_list
    @node_2.automatic_attrs[:platform] = 'ubuntu'
    @node_2.automatic_attrs[:hostname] = 'app01.example.com'

    @query_mock = mock()
    Chef::Search::Query.stub!(:new).and_return(@query_mock)
  end

  describe "run" do

    describe "without any arguments" do
      it "should search with the defaults and output the results" do
        @query_mock.should_receive(:search).with('node', '*:*', nil, 0, 20).and_yield(@node_1)
        @knife.name_args = ['node', '*:*']
        @knife.run
        ['web01', 'web01.example.com', 'recipe[apache]', 'recipe[ssl]', 'ubuntu'].each do |item|
          @stdout.string.should match(Regexp.escape(item))
        end
        @stdout.string.should match(Regexp.escape('"total": 1'))
      end
    end

    describe "with -b or --start" do
      it "should start at the provided row" do
        @knife.name_args = ['node', '*:*']
        @knife.config[:start] = 10
        @query_mock.should_receive(:search).with('node', '*:*', nil, 10, 20)
        @knife.run
        @stdout.string.should match(Regexp.escape('"start": 10'))
      end
    end

    describe "with -R or --rows" do
      it "should return upto the provided number of rows" do
        @knife.name_args = ['node', '*:*']
        @knife.config[:rows] = 15
        @query_mock.should_receive(:search).with('node', '*:*', nil, 0, 15)
        @knife.run
      end
    end

    describe "with -i or --id-only" do
      it "should return only the id" do
        @knife.name_args = ['node', '*:*']
        @knife.config[:id_only] = true 
        @query_mock.should_receive(:search).with('node', '*:*', nil, 0, 20).and_yield(@node_1)
        @knife.run
        @stdout.string.should match(/^web01$/)
      end
    end

    describe "with -r or --run-list" do
      it "should return only the id and run_list" do
        @knife.name_args = ['node', '*:*']
        @knife.config[:run_list] = true 
        @query_mock.should_receive(:search).with('node', '*:*', nil, 0, 20).and_yield(@node_1)
        @knife.run
        @stdout.string.should match(Regexp.escape('web01'))
        @stdout.string.should match(Regexp.escape('"recipe[apache]"'))
        @stdout.string.should match(Regexp.escape('"recipe[ssl]"'))
        ['ubuntu', 'web01.exmaple.com'].each do |item|
          @stdout.string.should_not match(Regexp.escape(item))
        end
      end
    end

    describe "with -a or --attribute" do
      it "should return only the id and desired attribute" do
        @knife.name_args = ['node', '*:*']
        @knife.config[:attribute] = 'platform'
        @query_mock.should_receive(:search).with('node', '*:*', nil, 0, 20).and_yield(@node_1)
        @knife.run
        @stdout.string.should match(Regexp.escape('web01'))
        @stdout.string.should match(Regexp.escape('ubuntu'))
        ['web01.example.com', 'apache', 'ssl'].each do |item|
          @stdout.string.should_not match(Regexp.escape(item))
        end
      end
    end

    describe "with -o or --sort" do
      it "should return results sorted as desired" do
        @knife.name_args = ['node', '*:*']
        @knife.config[:sort] = 'hostname desc'
        @query_mock.should_receive(:search).with('node', '*:*', 'hostname desc', 0, 20).and_yield([@node_2, @node_1])
        @knife.run
        @stdout.string.should match(/app01.+web01/m)
      end
    end

  end
end
