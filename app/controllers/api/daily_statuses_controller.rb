module Api
  class DailyStatusesController < ApplicationController
   
    before_action :set_daily_status, only: [:show, :edit, :update, :destroy]
    before_action :authorize_sales_executive_or_head, only: [:create]
    before_action :authorize_admin, only: [:update]

    # GET /daily_statuses
    def index
      @daily_statuses = if current_user.role == 'admin' || current_user.role == 'vp_sales'
                          # Admin can view all daily statuses
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product).all
                        elsif current_user.role == 'sales_head'
                          # Fetch reporting sales executives using sales_team
                          reporting_users = SalesTeam.where(manager_user_id: current_user.id).pluck(:user_id)
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product)
                                     .where(user_id: [current_user.id] + reporting_users)
                        elsif current_user.role == 'sales_executive'
                          # Sales executives can view only their own daily statuses
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product)
                                     .where(user_id: current_user.id)
                        else
                          # Fallback for unauthorized roles
                          return render json: { error: 'Unauthorized access' }, status: :forbidden
                        end

      render json: @daily_statuses.as_json(
        include: {
          decision_maker_contact: { only: [:id, :contact_name, :mobile, :decision_maker, :designation] },
          person_met_contact: { only: [:id, :contact_name, :mobile, :decision_maker, :designation] },
          user: { only: [:id, :username] },
          school: { only: [:id, :name, :email] },
          opportunity: {
            only: [:id, :opportunity_name],
            include: {
              product: { only: [:id, :product_name] }
            }
          }
        }
      )
    end

    # GET /daily_statuses/:id
    def show
      render json: @daily_status.as_json(
        include: {
          decision_maker_contact: { only: [:id, :contact_name, :mobile, :decision_maker] },
          person_met_contact: { only: [:id, :contact_name, :mobile, :decision_maker] }
        }
      )
    end

    # POST /daily_statuses
    def create
      @daily_status = DailyStatus.new(daily_status_params)
      @daily_status.createdby_user_id = current_user.id
      @daily_status.updatedby_user_id = current_user.id
      @daily_status.status = 'pending' # Default status when created

      if @daily_status.save
        render json: @daily_status, status: :created
      else
        render json: @daily_status.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /daily_statuses/:id
    def update
      @daily_status.updatedby_user_id = current_user.id # Update updatedby_user_id

      # Allow admin to change the status
      if daily_status_params[:status].present? && !%w[pending approved rejected].include?(daily_status_params[:status])
        return render json: { error: 'Invalid status value' }, status: :unprocessable_entity
      end

      if @daily_status.update(daily_status_params)
        render json: @daily_status, status: :ok
      else
        render json: { error: 'Failed to update daily status', details: @daily_status.errors }, status: :unprocessable_entity
      end
    end

    # DELETE /daily_statuses/:id
    def destroy
      @daily_status.destroy
      render json: { message: 'Daily status was successfully deleted.' }, status: :ok
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_daily_status
      @daily_status = DailyStatus.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Daily status not found' }, status: :not_found
    end

    # Restrict creation to sales executives
    def authorize_sales_executive_or_head
      unless current_user&.role.in?(['sales_executive', 'sales_head'])
        render json: { error: 'Only sales executives and sales heads can create daily statuses.' }, status: :forbidden
      end
    end

    # Restrict status updates to admins
    def authorize_admin
      if daily_status_params[:status].present? && current_user&.role != 'admin'
        render json: { error: 'Only admins can update the status.' }, status: :forbidden
      end
    end

    # Only allow a trusted parameter "white list" through.
    def daily_status_params
      params.require(:daily_status).permit(
        :user_id, :opportunity_id, :follow_up, :designation, :email,
        :discussion_point, :next_steps, :stage, :decision_maker_contact_id,
        :person_met_contact_id, :school_id, :status
      )
    end
  end
end
