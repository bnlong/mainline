class RepositoriesController < ApplicationController
  before_filter :login_required, :except => [:show, :writable_by]
  before_filter :find_project
  before_filter :require_adminship, :only => [:new, :create]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]
  session :off, :only => [:writable_by]
    
  def show
    @repository = @project.repositories.find_by_name!(params[:id])
    if @repository.has_commits?
      @commits = Git.bare(@repository.full_repository_path).log(10)
    else
      @commits = []
    end
    
    @atom_auto_discovery = true
    respond_to do |format|
      format.html
      format.xml  { render :xml => @repository }
      format.atom { render :template => "browse/index.atom.builder" }
    end
  end
  
  # note the #new+#create actions are members in the routes, hence they require
  # an id (of the repos to clone).
  def new
    @repository_to_clone = @project.repositories.find_by_name!(params[:id])
    @repository = Repository.new_by_cloning(@repository_to_clone, current_user.login)
  end
  
  def create
    @repository_to_clone = @project.repositories.find_by_name!(params[:id])
    @repository = Repository.new_by_cloning(@repository_to_clone)
    @repository.name = params[:repository][:name]
    @repository.user = current_user
    
    respond_to do |format|
      if @repository.save
        location = project_repository_path(@project, @repository)
        format.html { redirect_to location }
        format.xml  { render :xml => @repository, :status => :created, :location => location }        
      else
        format.html { render :action => "copy" }
        format.xml  { render :xml => @repository.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # Used internally to check write permissions by gitorious
  def writable_by
    @repository = @project.repositories.find_by_name!(params[:id])
    user = User.find_by_login(params[:username])
    if user && user.can_write_to?(@repository)
      render :text => "true"
    else
      render :text => "false"
    end
  end
  
  private
    def find_project
      @project = Project.find_by_slug!(params[:project_id])
    end
    
    def require_adminship
      unless @project.admin?(current_user)
        respond_to do |format|
          flash[:error] = "Sorry, only project admins are allowed to do that"
          format.html { redirect_to(project_path(@project)) }
          format.xml  { render :text => "Sorry, only project admins are allowed to do that", :status => :forbidden }
        end
        return
      end
    end
end
