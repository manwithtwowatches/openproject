#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController; def rescue_action(e) raise e end; end

class RepositoriesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_revisions
    get :revisions, :project_id => 1
    assert_response :success
    assert_template 'revisions'
    assert_not_nil assigns(:changesets)
  end

  def test_revision
    get :revision, :project_id => 1, :rev => 1
    assert_response :success
    assert_not_nil assigns(:changeset)
    assert_equal "1", assigns(:changeset).revision
  end

  def test_revision_with_before_nil_and_after_normal
    get :revision, {:project_id => 1, :rev => 1}
    assert_response :success
    assert_template 'revision'
    assert_no_tag :tag => "div", :attributes => { :class => "contextual" },
      :child => { :tag => "a", :attributes => { :href => @controller.url_for(:only_path => true,
                                                                             :controller => 'repositories',
                                                                             :action => 'revision',
                                                                             :project_id => 'ecookbook',
                                                                             :rev => '0') } }
    assert_tag :tag => "div", :attributes => { :class => "contextual" },
      :child => { :tag => "a", :attributes => { :href => @controller.url_for(:only_path => true,
                                                                             :controller => 'repositories',
                                                                             :action => 'revision',
                                                                             :project_id => 'ecookbook',
                                                                             :rev => '2') } }
  end

  def test_graph_commits_per_month
    get :graph, :project_id => 1, :graph => 'commits_per_month'
    assert_response :success
    assert_equal 'image/svg+xml', @response.content_type
  end

  def test_committers
    @request.session[:user_id] = 2
    # add a commit with an unknown user
    Changeset.create!(
        :repository => Project.find(1).repository,
        :committer  => 'foo',
        :committed_on => Time.now,
        :revision => 100,
        :comments => 'Committed by foo.'
     )

    get :committers, :project_id => 1
    assert_response :success
    assert_template 'committers'

    assert_tag :td, :content => 'dlopper',
                    :sibling => { :tag => 'td',
                                  :child => { :tag => 'select', :attributes => { :name => %r{^committers\[\d+\]\[\]$} },
                                                                :child => { :tag => 'option', :content => 'Dave Lopper',
                                                                                              :attributes => { :value => '3', :selected => 'selected' }}}}
    assert_tag :td, :content => 'foo',
                    :sibling => { :tag => 'td',
                                  :child => { :tag => 'select', :attributes => { :name => %r{^committers\[\d+\]\[\]$} }}}
    assert_no_tag :td, :content => 'foo',
                       :sibling => { :tag => 'td',
                                     :descendant => { :tag => 'option', :attributes => { :selected => 'selected' }}}
  end

  def test_map_committers
    @request.session[:user_id] = 2
    # add a commit with an unknown user
    c = Changeset.create!(
            :repository => Project.find(1).repository,
            :committer  => 'foo',
            :committed_on => Time.now,
            :revision => 100,
            :comments => 'Committed by foo.'
          )
    assert_no_difference "Changeset.count(:conditions => 'user_id = 3')" do
      post :committers, :project_id => 1, :committers => { '0' => ['foo', '2'], '1' => ['dlopper', '3']}
      assert_redirected_to '/projects/ecookbook/repository/committers'
      assert_equal User.find(2), c.reload.user
    end
  end
end
