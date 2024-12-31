class Api::SalesTeamsController < ApplicationController
  before_action :set_sales_team, only: [:show, :update, :destroy]

  # GET /api/sales_teams
  def index
    @sales_teams = SalesTeam.all
    render json: @sales_teams, include: ['sales_team', 'manager']
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
