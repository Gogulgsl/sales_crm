class Api::OpportunitiesController < ApplicationController
  before_action :authorize_user, except: [:index, :show, :active_opportunities]
  before_action :set_opportunity, only: [:show, :update, :destroy]

  # GET /api/opportunities
  def index
    opportunities = Opportunity.includes(:product, :school, :user, :contact).all
    render json: opportunities.as_json(include: [:product, :school, :user, :contact]), status: :ok
  end

  # GET /api/opportunities/:id
  def show
    render json: @opportunity.as_json(include: [:product, :school, :user, :contact]), status: :ok
  end

  # GET /api/opportunities/active_opportunities
  def active_opportunities
    opportunities = Opportunity.includes(:product, :school, :user, :contact)
                                .where(is_active: true)
    render json: opportunities.as_json(include: [:product, :school, :user, :contact]), status: :ok
  end

  # GET /api/opportunities/my_opportunities
  def my_opportunities
    opportunities = Opportunity.includes(:product, :school, :user, :contact)
                                .where(user_id: current_user.id, is_active: true)

    if opportunities.exists?
      render json: opportunities.as_json(include: [:product, :school, :user, :contact]), status: :ok
    else
      render json: { error: 'No opportunities found for the user' }, status: :not_found
    end
  end

  # POST /api/opportunities
  def create
    user = User.find_by(id: opportunity_params[:user_id]) || current_user

    opportunity = Opportunity.new(opportunity_params)
    opportunity.user = user
    opportunity.createdby_user_id = user.id
    opportunity.updatedby_user_id = user.id

    if opportunity.save
      render json: opportunity.as_json(include: [:product, :school, :user, :contact]), status: :created
    else
      render json: opportunity.errors, status: :unprocessable_entity
    end
  end

  # PUT /api/opportunities/:id
  def update
    if @opportunity.update(opportunity_params)
      render json: @opportunity.as_json(include: [:product, :school, :user, :contact]), status: :ok
    else
      render json: @opportunity.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/opportunities/:id
  def destroy
    @opportunity.destroy
    head :no_content
  end

  private

  # Fetch opportunity by ID
  def set_opportunity
    @opportunity = Opportunity.includes(:product, :school, :user, :contact).find(params[:id])
  end

  # Permit opportunity parameters
  def opportunity_params
    params.require(:opportunity).permit(
      :school_id, :product_id, :start_date, :user_id, 
      :opportunity_name, :createdby_user_id, :updatedby_user_id, 
      :last_stage, :is_active, :contact_id
    )
  end

  # Ensure the request has a valid Authorization header
  def authorize_user
    render json: { error: 'Unauthorized' }, status: :unauthorized unless request.headers['Authorization'].present?
  end
end
