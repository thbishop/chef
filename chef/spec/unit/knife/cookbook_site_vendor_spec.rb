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

describe Chef::Knife::CookbookSiteVendor do

  before(:each) do
    @knife = Chef::Knife::CookbookSiteVendor.new
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
    describe "when providing a cookbook name" do
      before(:each) do
        @cookbook_name = 'pizza'
        @knife.name_args = [@cookbook_name]
        @cookbook_path = '/opt/chef/cookbooks'
        Chef::Config[:cookbook_path] = @cookbook_path
      end

      it "should log an error and exit if our cookbook path is invalid" do
        lambda {
          File.should_receive(:directory?).with(@cookbook_path).and_return(false)
          @knife.run
        }.should raise_error(SystemExit) { |e| e.status.should == 1 }

        @log_stringio.string.should match(Regexp.escape("ERROR -- : #{@cookbook_path}/ doesn\'t exist!.  Make sure you have cookbook_path configured correctly"))
      end

      describe "and when our cookbook path is valid" do
        before(:each) do
          File.should_receive(:directory?).with(@cookbook_path).and_return(true)
          @cookbook_site_download_mock = mock()
          @cookbook_site_download_mock.should_receive(:[]=).with(:file, "#{@cookbook_path}/pizza.tar.gz")
          @cookbook_site_download_mock.should_receive(:config).and_return(@cookbook_site_download_mock)
          @cookbook_site_download_mock.should_receive(:name_args=).with(['pizza'])
          @cookbook_site_download_mock.should_receive(:run)
          Chef::Knife::CookbookSiteDownload.should_receive(:new).and_return(@cookbook_site_download_mock)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path) 
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "rm -r #{@cookbook_path}/pizza", :cwd => @cookbook_path)
          File.should_receive(:directory?).with("#{@cookbook_path}/pizza").and_return(true)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "tar zxvf #{@cookbook_path}/pizza.tar.gz", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "rm #{@cookbook_path}/pizza.tar.gz", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git add pizza", :cwd => @cookbook_path)
        end

        it "should create the vendor branch if doesn't exist, download the cookbok, create a tag, and merge the changes into master" do
          @cookbook_site_download_mock.should_receive(:version).exactly(6).times.and_return('0.1.3')
          Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pasta', ''])
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout -b chef-vendor-pizza", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-0.1.3", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
          Dir.should_receive(:chdir).with(@cookbook_path).and_yield
          @knife.should_receive(:system).with("git merge chef-vendor-pizza").and_return(true)
          @knife.run

          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Creating vendor branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Removing pre-existing version.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Creating tag chef-vendor-pizza-0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Merging changes from pizza version 0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Cookbook pizza version 0.1.3 successfully vendored!'))
        end

        it "should checkout the vendor branch if it already exists, download the cookbook, create a tag, and merge the changes into master" do
          @cookbook_site_download_mock.should_receive(:version).exactly(6).times.and_return('0.1.3')
          Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-0.1.3", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
          Dir.should_receive(:chdir).with(@cookbook_path).and_yield
          @knife.should_receive(:system).with("git merge chef-vendor-pizza").and_return(true)
          @knife.run

          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Vendor branch found.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Merging changes from pizza version 0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Cookbook pizza version 0.1.3 successfully vendored!'))
        end

        it "should not create a tag or merge if there are no changes" do
          @cookbook_site_download_mock.should_receive(:version).twice.and_return('0.1.3')
          Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path).and_raise(Chef::Exceptions::Exec)
          Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
          Chef::Mixin::Command.should_not_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-1.0.3", :cwd => @cookbook_path)
          @knife.run

          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Vendor branch found.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
          @log_stringio.string.should match(Regexp.escape('WARN -- : Checking out the master branch.'))
          @log_stringio.string.should match(Regexp.escape('WARN -- : No changes from current vendor pizza'))
        end

        it "should should log an error and exit if there are issues merging into master after creating a tag" do
          lambda {
            @cookbook_site_download_mock.should_receive(:version).exactly(5).times.and_return('0.1.3')
            Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-0.1.3", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
            Dir.should_receive(:chdir).with(@cookbook_path).and_yield
            @knife.should_receive(:system).with("git merge chef-vendor-pizza").and_return(false)
            @knife.run
          }.should raise_error(SystemExit) { |e| e.status.should == 1 }

          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Vendor branch found.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Removing pre-existing version.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Creating tag chef-vendor-pizza-0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
          @log_stringio.string.should match(Regexp.escape('INFO -- : Merging changes from pizza version 0.1.3.'))
          @log_stringio.string.should match(Regexp.escape('ERROR -- : You have merge conflicts - please resolve manually!'))
          @log_stringio.string.should match(Regexp.escape("ERROR -- : (Hint: cd #{@cookbook_path}; git status)"))
        end

        describe "and with -d or --dependencies" do
          before(:each) do
            @knife.config[:deps] = true
            @cookbook_site_download_mock.should_receive(:version).twice.and_return('0.1.3')
            Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path).and_raise(Chef::Exceptions::Exec)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_not_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-1.0.3", :cwd => @cookbook_path)
          end

          it "should include the dependencies" do
            cookbook_metadata_mock = mock()
            cookbook_metadata_dependency_mock = mock()
            cookbook_metadata_dependency_mock.stub!(:each).and_yield('dough', '0.2.0').and_yield('cheese', '0.1.3')
            cookbook_metadata_mock.should_receive(:from_file).with("#{@cookbook_path}/pizza/metadata.rb")
            cookbook_metadata_mock.should_receive(:dependencies).and_return(cookbook_metadata_dependency_mock)
            Chef::Cookbook::Metadata.should_receive(:new).and_return(cookbook_metadata_mock)
            cookbook_site_vendor_mock_1 = mock()
            cookbook_site_vendor_mock_2 = mock()

            Chef::Knife::CookbookSiteVendor.should_receive(:new).twice.and_return(cookbook_site_vendor_mock_1, cookbook_site_vendor_mock_2)

            { 'dough' => cookbook_site_vendor_mock_1, 'cheese' => cookbook_site_vendor_mock_2}.each_pair do |cookbook_name, cookbook_vendor_mock|
              cookbook_vendor_mock.should_receive(:config=).with(@knife.config)
              cookbook_vendor_mock.should_receive(:name_args=).with([cookbook_name])
              cookbook_vendor_mock.should_receive(:run)
            end

            @knife.run
          end
        end

      end

      describe "and specifying a path with -o or --cookbook-path" do
        before(:each) do
          @cookbook_path = '/opt/chef/other_cookbook_path'
          @knife.config[:cookbook_path] = @cookbook_path
        end

        it "should use the specified cookbook path" do
          lambda {
            File.should_receive(:directory?).with(@cookbook_path).and_return(false)
            @knife.run
          }.should raise_error(SystemExit) { |e| e.status.should == 1 }

          @log_stringio.string.should match(Regexp.escape("ERROR -- : #{@cookbook_path}/ doesn\'t exist!.  Make sure you have cookbook_path configured correctly"))
        end

        describe "and when our cookbook path is valid" do
          before(:each) do
            File.should_receive(:directory?).with(@cookbook_path).and_return(true)
            @cookbook_site_download_mock = mock()
            @cookbook_site_download_mock.should_receive(:[]=).with(:file, "#{@cookbook_path}/pizza.tar.gz")
            @cookbook_site_download_mock.should_receive(:config).and_return(@cookbook_site_download_mock)
            @cookbook_site_download_mock.should_receive(:name_args=).with(['pizza'])
            @cookbook_site_download_mock.should_receive(:run)
            Chef::Knife::CookbookSiteDownload.should_receive(:new).and_return(@cookbook_site_download_mock)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path) 
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "rm -r #{@cookbook_path}/pizza", :cwd => @cookbook_path)
            File.should_receive(:directory?).with("#{@cookbook_path}/pizza").and_return(true)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "tar zxvf #{@cookbook_path}/pizza.tar.gz", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "rm #{@cookbook_path}/pizza.tar.gz", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git add pizza", :cwd => @cookbook_path)
          end

          it "should create the vendor branch if doesn't exist, download the cookbok, create a tag, and merge the changes into master" do
            @cookbook_site_download_mock.should_receive(:version).exactly(6).times.and_return('0.1.3')
            Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pasta', ''])
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout -b chef-vendor-pizza", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-0.1.3", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
            Dir.should_receive(:chdir).with(@cookbook_path).and_yield
            @knife.should_receive(:system).with("git merge chef-vendor-pizza").and_return(true)
            @knife.run

            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Creating vendor branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Removing pre-existing version.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Creating tag chef-vendor-pizza-0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Merging changes from pizza version 0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Cookbook pizza version 0.1.3 successfully vendored!'))
          end

          it "should checkout the vendor branch if it already exists, download the cookbook, create a tag, and merge the changes into master" do
            @cookbook_site_download_mock.should_receive(:version).exactly(6).times.and_return('0.1.3')
            Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-0.1.3", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
            Dir.should_receive(:chdir).with(@cookbook_path).and_yield
            @knife.should_receive(:system).with("git merge chef-vendor-pizza").and_return(true)
            @knife.run

            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Vendor branch found.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Merging changes from pizza version 0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Cookbook pizza version 0.1.3 successfully vendored!'))
          end

          it "should not create a tag or merge if there are no changes" do
            @cookbook_site_download_mock.should_receive(:version).twice.and_return('0.1.3')
            Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path).and_raise(Chef::Exceptions::Exec)
            Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
            Chef::Mixin::Command.should_not_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-1.0.3", :cwd => @cookbook_path)
            @knife.run

            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Vendor branch found.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
            @log_stringio.string.should match(Regexp.escape('WARN -- : Checking out the master branch.'))
            @log_stringio.string.should match(Regexp.escape('WARN -- : No changes from current vendor pizza'))
          end

          it "should should log an error and exit if there are issues merging into master after creating a tag" do
            lambda {
              @cookbook_site_download_mock.should_receive(:version).exactly(5).times.and_return('0.1.3')
              Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
              Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
              Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path)
              Chef::Mixin::Command.should_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-0.1.3", :cwd => @cookbook_path)
              Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
              Dir.should_receive(:chdir).with(@cookbook_path).and_yield
              @knife.should_receive(:system).with("git merge chef-vendor-pizza").and_return(false)
              @knife.run
            }.should raise_error(SystemExit) { |e| e.status.should == 1 }

            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking the status of the vendor branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Vendor branch found.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Removing pre-existing version.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Uncompressing pizza version 0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Adding changes.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Committing changes.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Creating tag chef-vendor-pizza-0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Checking out the master branch.'))
            @log_stringio.string.should match(Regexp.escape('INFO -- : Merging changes from pizza version 0.1.3.'))
            @log_stringio.string.should match(Regexp.escape('ERROR -- : You have merge conflicts - please resolve manually!'))
            @log_stringio.string.should match(Regexp.escape("ERROR -- : (Hint: cd #{@cookbook_path}; git status)"))
          end

          describe "and with -d or --dependencies" do
            before(:each) do
              @knife.config[:deps] = true
              @cookbook_site_download_mock.should_receive(:version).twice.and_return('0.1.3')
              Chef::Mixin::Command.should_receive(:output_of_command).with("git branch --no-color | grep chef-vendor-pizza", :cwd => @cookbook_path) .and_return([0, 'chef-vendor-pizza', ''])
              Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout chef-vendor-pizza", :cwd => @cookbook_path)
              Chef::Mixin::Command.should_receive(:run_command).with(:command => "git commit -a -m 'Import pizza version 0.1.3'", :cwd => @cookbook_path).and_raise(Chef::Exceptions::Exec)
              Chef::Mixin::Command.should_receive(:run_command).with(:command => "git checkout master", :cwd => @cookbook_path)
              Chef::Mixin::Command.should_not_receive(:run_command).with(:command => "git tag -f chef-vendor-pizza-1.0.3", :cwd => @cookbook_path)
            end

            it "should include the dependencies" do
              cookbook_metadata_mock = mock()
              cookbook_metadata_dependency_mock = mock()
              cookbook_metadata_dependency_mock.stub!(:each).and_yield('dough', '0.2.0').and_yield('cheese', '0.1.3')
              cookbook_metadata_mock.should_receive(:from_file).with("#{@cookbook_path}/pizza/metadata.rb")
              cookbook_metadata_mock.should_receive(:dependencies).and_return(cookbook_metadata_dependency_mock)
              Chef::Cookbook::Metadata.should_receive(:new).and_return(cookbook_metadata_mock)
              cookbook_site_vendor_mock_1 = mock()
              cookbook_site_vendor_mock_2 = mock()

              Chef::Knife::CookbookSiteVendor.should_receive(:new).twice.and_return(cookbook_site_vendor_mock_1, cookbook_site_vendor_mock_2)

              { 'dough' => cookbook_site_vendor_mock_1, 'cheese' => cookbook_site_vendor_mock_2}.each_pair do |cookbook_name, cookbook_vendor_mock|
                cookbook_vendor_mock.should_receive(:config=).with(@knife.config)
                cookbook_vendor_mock.should_receive(:name_args=).with([cookbook_name])
                cookbook_vendor_mock.should_receive(:run)
              end

              @knife.run
            end
          end
        end
      end

    end
  end
end
