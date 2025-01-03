class Api::OpportunitiesController < ApplicationController
  before_action :authorize_user, except: [:show, :active_opportunities]
  before_action :set_opportunity, only: [:show, :update, :destroy]

  # GET /api/opportunities
  def index
    case current_user.role
    when 'admin', 'vp_sales'
      opportunities = Opportunity.includes(:product, :school, :user, :contact).all

    when 'sales_head'
      reporting_executives = SalesTeam.where(manager_user_id: current_user.id).pluck(:user_id)
      opportunities = Opportunity.includes(:product, :school, :user, :contact)
                                  .where(user_id: [current_user.id] + reporting_executives)

    when 'sales_executive'
      opportunities = Opportunity.includes(:product, :school, :user, :contact)
                                  .where(user_id: current_user.id)

    else
      # If the role is unrecognized, return unauthorized error
      render json: { error: 'Unauthorized access' }, status: :forbidden
      return
    end

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

  def logs
    logs = OpportunityLog.includes(:opportunity, opportunity: [:school, :product, :user, :contact]).order(created_at: :desc)

    render json: logs.as_json(
      include: {
        opportunity: {
          include: {
            school: { only: [:id, :name] },
            product: { only: [:id, :product_name] },
            user: { only: [:id, :username] },
            contact: { only: [:id, :contact_name, :mobile, :designation] }
          },
          except: [:created_at, :updated_at]
        }
      },
      except: [:updated_at]
    ), status: :ok
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
      :last_stage, :is_active, :contact_id, :zone
    )
  end

  # Ensure the request has a valid Authorization header
  def authorize_user
    render json: { error: 'Unauthorized' }, status: :unauthorized unless request.headers['Authorization'].present?
  end
end
