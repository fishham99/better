# BetterMeans - Work 2.0
# Copyright (C) 2006-2011  See readme for details and license#

class NewsController < ApplicationController
  default_search_scope :news
  before_filter :find_news, :except => [:new, :index, :preview]
  before_filter :find_project, :only => [:new, :preview]
  before_filter :authorize, :except => [:index, :preview]
  before_filter :find_optional_project, :only => :index
  accept_key_auth :index
  ssl_required :all


  log_activity_streams :current_user, :name, :announced, :@news, :title, :new, :news, {:object_description_method => :summary}
  log_activity_streams :current_user, :name, :edited, :@news, :title, :edit, :news, {:object_description_method => :summary}
  log_activity_streams :current_user, :name, :commented_on, :@news, :title, :add_comment, :news, {
              :object_description_method => :summary,
              :indirect_object => :@comment,
              :indirect_object_description_method => :comments,
              :indirect_object_phrase => '' }

  def index # spec_me cover_me heckle_me
    @news_pages, @newss = paginate :news,
                                   :per_page => 10,
                                   :conditions => Project.allowed_to_condition(User.current, :view_news, :project => @project),
                                   :include => [:author, :project],
                                   :order => "#{News.table_name}.created_at DESC"
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.xml { render :xml => @newss.to_xml }
      format.json { render :json => @newss.to_json }
    end
  end

  def show # spec_me cover_me heckle_me
    @comments = @news.comments
    @comments.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def new # spec_me cover_me heckle_me
    @news = News.new(:project => @project, :author => User.current)
    if request.post?
      @news.attributes = params[:news]
      if @news.save
        flash.now[:success] = l(:notice_successful_create)
        redirect_to :controller => 'news', :action => 'index', :project_id => @project
      end
    end
  end

  def edit # spec_me cover_me heckle_me
    if request.post? and @news.update_attributes(params[:news])
      flash.now[:success] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @news
    end
  end

  def add_comment # spec_me cover_me heckle_me
    @comment = Comment.new(params[:comment])
    @comment.author = User.current
    if @news.comments << @comment
      flash.now[:success] = l(:label_comment_added)
      redirect_to :action => 'show', :id => @news
    else
      show
      render :action => 'show'
    end
  end

  def destroy_comment # spec_me cover_me heckle_me
    @news.comments.find(params[:comment_id]).destroy
    redirect_to :action => 'show', :id => @news
  end

  def destroy # spec_me cover_me heckle_me
    @news.destroy
    redirect_to :action => 'index', :project_id => @project
  end

  def preview # spec_me cover_me heckle_me
    @text = (params[:news] ? params[:news][:description] : nil)
    render :partial => 'common/preview'
  end

  private

  def find_news # cover_me heckle_me
    @news = News.find(params[:id])
    @project = @news.project
    render_message l(:text_project_locked) if @project.locked?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project # cover_me heckle_me
    @project = Project.find(params[:project_id])
    render_message l(:text_project_locked) if @project.locked?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project # cover_me heckle_me
    return true unless params[:project_id]
    @project = Project.find(params[:project_id])
    render_message l(:text_project_locked) if @project.locked?
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
