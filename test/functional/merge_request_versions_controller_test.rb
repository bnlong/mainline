# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require "test_helper"

class MergeRequestVersionsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context

  context "Viewing diffs" do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @merge_request.stubs(:calculate_merge_base).returns("ffac0")
      @version = @merge_request.create_new_version
      @git = mock

      #(repo, id, parents, tree, author, authored_date, committer, committed_date, message)
      @commit = Grit::Commit.new(mock("repo"), "mycommitid", [], stub_everything("tree"),
                                 stub_everything("author"), Time.now, stub_everything("comitter"), Time.now,
                                 "my commit message".split(" "))

      Repository.any_instance.stubs(:git).returns(@git)
      MergeRequestVersion.stubs(:find).returns(@version)
    end

    should "view the diff for a single commit" do
      @version.expects(:diffs).with("ffcab").returns([])
      @git.expects(:commit).with("ffcab").returns(@commit)

      get :show, params(:id => @version.to_param, :commit_shas => "ffcab")

      assert_response :success
      assert_equal @commit, assigns(:commit)
    end

    should "view the diff for a series of commits" do
      @version.expects(:diffs).with("ffcab".."bacff").returns([])

      get :show, params(:id => @version, :commit_shas => "ffcab-bacff")

      assert_response :success
      assert_nil assigns(:commit)
    end

    should "view the entire diff" do
      @version.expects(:diffs).returns([])

      get :show, params(:id => @version)

      assert_response :success
      assert_not_nil assigns(:project)
    end

    context "With private projects" do
      setup do
        @project = @merge_request.project
        enable_private_repositories
        @version.stubs(:diffs).with("ffcab".."bacff").returns([])
      end

      should "disallow unauthenticated users" do
        get :show, params(:id => @version, :commit_shas => "ffcab-bacff")
        assert_response 403
      end

      should "allow authenticated users" do
        login_as :johan
        get :show, params(:id => @version, :commit_shas => "ffcab-bacff")
        assert_response 200
      end
    end

    context "With private repositories" do
      setup do
        enable_private_repositories(@merge_request.target_repository)
        @version.stubs(:diffs).with("ffcab".."bacff").returns([])
      end

      should "disallow unauthenticated users" do
        get :show, params(:id => @version, :commit_shas => "ffcab-bacff")
        assert_response 403
      end

      should "allow authenticated users" do
        login_as :johan
        get :show, params(:id => @version, :commit_shas => "ffcab-bacff")
        assert_response 200
      end
    end
  end

  def params(extras)
    { :project_id => "gitorious",
      :repository_id => "repository",
      :merge_request_id => 1,
      :format => "js" }.merge(extras)
  end
end
