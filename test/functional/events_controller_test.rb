# encoding: utf-8
#--
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

require File.dirname(__FILE__) + '/../test_helper'

class EventsControllerTest < ActionController::TestCase

  def setup
    @project = projects(:johans)
    @repository = repositories(:johans)
  end
  
  context "#index" do
    should "shows news" do
      @project.create_event(Action::CREATE_PROJECT, @project, users(:johan), "", "")
      get :index
      assert_response :success
      assert_equal 1, assigns(:events).size
    end
  end
  
  context 'commits' do
    setup do
      @push_event = @project.create_event(Action::PUSH, @repository, User.first,
                                          "", "A push event", 10.days.ago)
      10.times do |n|
        c = @push_event.build_commit({
          :email => 'John Doe <john@doe.org>',
          :body => "Commit number #{n}",
          :data => "ffc0#{n}"
        })
        c.save
      end
    end
    
    should 'show commits under a push event' do
      get :commits, :id => @push_event.to_param, :format => 'js'
      assert_response :success
    end
    
    should "cache the commit events" do
      get :commits, :id => @push_event.to_param, :format => 'js'
      assert_response :success
      assert_equal "max-age=1800, private", @response.headers['Cache-Control']
    end
  end

  context "commits read from git, AKA new style push" do
    setup do
      @first_sha = "a"*32
      @last_sha = "f"*32
      event_data = [@first_sha, @last_sha, "master","10"].join(PushEventLogger::PUSH_EVENT_DATA_SEPARATOR)
      @push_event = @project.create_event(Action::PUSH_SUMMARY, @repository, User.first,
        event_data, "", 10.days.ago)
    end

    should "fetch the commits from git" do
      @grit = mock
      commits = []
      @grit.expects(:commits_between).with(@first_sha, @last_sha).returns(commits)
      Repository.any_instance.stubs(:git).returns(@grit)
      get :commits, :id => @push_event.to_param, :format => 'js'
      assert_response :success
    end

    should "be cached" do
      Rails.cache.expects(:fetch).with("commits_in_push_event_#{@push_event.to_param}").returns([])
      get :commits, :id => @push_event.to_param, :format => 'js'
      assert_response :success
    end
  end

end
