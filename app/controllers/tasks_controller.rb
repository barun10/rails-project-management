class TasksController < ApplicationController
  layout "tasks_layout"
  before_action :set_task
  before_action :set_project
  before_action :project_task_statuses_count, only: [:index, :complete, :overdue]

  ## STANDARD RESTFUL ACTIONS

  def index
    @task = Task.new(project_id: @project.id)
    authorize @task
    @tasks = @project.active_tasks
  end

  def new
    @task = Task.new(project_id: @project.id)
    authorize @task
    @task_users = task_users
  end

  def create
    @task = Task.new(task_params)
    authorize @task
    if @task.save
      redirect_to task_path(@task)
    else
      render :new
    end
  end

  def show
    @project = @task.project
    @comment = Comment.new
    @comments = @task.comments.reverse
    @assigned_users = @task.assigned_users
    @tags = @task.tags
  end

  def edit
    authorize @task
    @project = @task.project
     @task_users = task_users
  end

  def update
    authorize @task
    @task.tags.clear
    @task.update(task_params)
    redirect_to task_path(@task)
  end

  def destroy
    authorize @task
    @task.destroy
    redirect_to project_tasks_path(@project)
  end

  ## ADDITIONAL ACTIONS

  # PROJECT TASKS 
  def complete
    @tasks = @project.complete_tasks
  end

  def overdue
    @tasks = @project.overdue_tasks
  end

  # ALL USER RELATED TASKS
  def all_active_tasks
    @tasks = @user.tasks.active + @user.assigned_tasks.active
    @tasks.flatten.uniq
  end

  def all_complete_tasks
    @tasks = @user.tasks.complete + @user.assigned_tasks.complete
    @tasks.flatten.uniq
  end

  def all_overdue_tasks
    @tasks = @user.tasks.overdue + @user.assigned_tasks.overdue
    @tasks.flatten.uniq
  end

  def quick_new_task
   @task = Task.new
   @projects = @user.active_projects + @user.collaboration_projects.active
  end

  ## PRIVATE METHODS

  private
  def set_user
    @user = current_user
  end

  def set_task
    @task = Task.find_by(id: params[:id])
  end

  def set_project
    @project = Project.find_by(id: params[:project_id])
  end

  def project_task_statuses_count
    @overdue = @project.overdue_tasks.count
    @active = @project.active_tasks.count
    @complete = @project.complete_tasks.count
  end

  def task_params
    params.require(:task).permit(:name, :description, :project_id, :owner_id, :due_date, :status, :tag_names, assigned_user_ids: [])
  end

  def task_users
    task_users = []
    task_users << @task.project.collaborators
    task_users << @user
    task_users.flatten
  end
end
