class IssuesController < ApplicationController
  before_filter :load_issue, only: [:show, :edit, :update, :destroy, :geometry,
                                    :vote_up, :vote_down, :vote_clear]
  filter_access_to [:edit, :update, :destroy], attribute_check: true

  def index
    issues = Issue.by_most_recent.paginate(page: params[:page]).includes(:created_by)

    # work around till https://github.com/bouchard/thumbs_up/issues/64 is fixed
    popular_issue_ids = Issue.plusminus_tally(start_at: 8.weeks.ago, at_least: 1).map &:id
    popular_issues = Issue.where(id: popular_issue_ids).paginate(page: params[:pop_issues_page]).includes(:created_by)

    @issues = IssueDecorator.decorate(issues)
    @popular_issues = IssueDecorator.decorate(popular_issues)
    @start_location = index_start_location
  end

  def show
    @issue = IssueDecorator.decorate(@issue)
    set_page_title @issue.title
    @threads = ThreadListDecorator.decorate(@issue.threads.order_by_latest_message.includes(:group))
    @tag_panel = TagPanelDecorator.new(@issue, form_url: issue_tags_path(@issue))
  end

  def new
    @issue = Issue.new
    @start_location = current_user.start_location
  end

  def create
    @issue = current_user.issues.new permitted_params

    if @issue.save
      NewIssueNotifier.new_issue(@issue)
      redirect_to new_issue_thread_path(@issue)
    else
      @start_location = current_user.start_location
      render :new
    end
  end

  def edit
    @start_location = @issue.location
  end

  def update
    if @issue.update_attributes permitted_params
      set_flash_message(:success)
      redirect_to action: :show
    else
      @start_location = current_user.start_location
      render :edit
    end
  end

  def destroy
    if @issue.destroy
      set_flash_message(:success)
      redirect_to issues_path
    else
      set_flash_message(:failure)
      redirect_to @issue
    end
  end

  def geometry
    respond_to do |format|
      format.json { render json: RGeo::GeoJSON.encode(issue_feature(IssueDecorator.decorate(@issue))) }
    end
  end

  def all_geometries
    if params[:bbox]
      bbox = bbox_from_string(params[:bbox], Issue.rgeo_factory)
      issues = Issue.intersects_not_covered(bbox.to_geometry).order('created_at DESC').limit(50)
    else
      bbox = nil
      issues = Issue.order('created_at DESC').limit(50)
    end
    factory = RGeo::GeoJSON::EntityFactory.new
    collection = factory.feature_collection(issues.sort_by! { |o| o.size }.reverse.map { | issue | issue_feature(IssueDecorator.decorate(issue), bbox) })
    respond_to do |format|
      format.json { render json: RGeo::GeoJSON.encode(collection) }
    end
  end

  def vote_up
    if current_user.voted_for? @issue
      set_flash_message :already
    else
      current_user.vote_exclusively_for @issue
      set_flash_message :success
    end
    redirect_to @issue
  end

  def vote_down
    if current_user.voted_against? @issue
      set_flash_message :already
    else
      current_user.vote_exclusively_against @issue
      set_flash_message :success
    end
    redirect_to @issue
  end

  def vote_clear
    if current_user.clear_votes @issue
      set_flash_message :success
    else
      set_flash_message :failure
    end
    redirect_to @issue
  end

  protected

  def index_start_location
    return current_user.start_location if current_user && current_user.start_location != Geo::NOWHERE_IN_PARTICULAR
    return current_group.start_location if current_group && current_group.start_location
    return @issues.first.location unless @issues.empty?
    return Geo::NOWHERE_IN_PARTICULAR
  end

  def issue_feature(issue, bbox = nil)
    geom = bbox.to_geometry if bbox
    issue.loc_feature(thumbnail: issue.medium_icon_path,
                      image_url: issue.tip_icon_path(false),
                      title: issue.title,
                      size_ratio: issue.size_ratio(geom),
                      url: view_context.url_for(issue),
                      created_by: issue.created_by.name,
                      created_by_url: view_context.url_for(issue.created_by))
  end

  def load_issue
    @issue ||= Issue.find(params[:id])
  end

  def permitted_params
    params.require(:issue).permit :title, :photo, :retained_photo, :loc_json, :tags_string,
      :description
  end
end
