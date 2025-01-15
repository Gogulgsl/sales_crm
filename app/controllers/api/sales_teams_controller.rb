class Api::SalesTeamsController < ApplicationController
  before_action :set_sales_team, only: [:show, :update, :destroy]

  # GET /api/sales_teams
  def index
    case current_user.role
    when 'admin'
      # Admin sees all data
      @sales_teams = SalesTeam.includes(:user, :manager_user)
    when 'sales_head'
      # Sales Head sees their sales executives
      @sales_teams = SalesTeam.includes(:user, :manager_user).where(manager_user_id: current_user.id)
    else
      render json: { error: 'Unauthorized access' }, status: :forbidden
      return
    end

    render json: @sales_teams, include: ['user', 'manager_user']
  end


  # GET /api/sales_teams/:id
  def show
    render json: @sales_team, include: ['sales_team', 'manager']
  end

  # POST /api/sales_teams
  def create
    @sales_team = SalesTeam.new(sales_team_params)

    if @sales_team.save
      render json: @sales_team, status: :created, location: api_sales_team_url(@sales_team)
    else
      render json: @sales_team.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/sales_teams/:id
  def update
    if @sales_team.update(sales_team_params)
      render json: @sales_team
    else
      render json: @sales_team.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/sales_teams/:id
  def destroy
    @sales_team.destroy
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sales_team
      @sales_team = SalesTeam.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def sales_team_params
      params.require(:sales_team).permit(:user_id, :designation, :manager_user_id)
    end
end
