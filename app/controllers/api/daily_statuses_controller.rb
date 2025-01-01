module Api
  class DailyStatusesController < ApplicationController
   
    before_action :set_daily_status, only: [:show, :edit, :update, :destroy]
    before_action :authorize_sales_executive, only: [:create]
    before_action :authorize_admin, only: [:update]

    # GET /daily_statuses
    def index
      if current_user.role == 'sales_executive'
        # Restrict to daily statuses created by the logged-in sales executive
        @daily_statuses = DailyStatus.includes(
          :decision_maker_contact, 
          :person_met_contact, 
          :user, 
          :school,
          opportunity: :product
        ).where(user_id: current_user.id)
      else
        # Admins or other roles can view all daily statuses
        @daily_statuses = DailyStatus.includes(
          :decision_maker_contact, 
          :person_met_contact, 
          :user, 
          :school,
          opportunity: :product
        )
      end

      render json: @daily_statuses.as_json(
        include: {
          decision_maker_contact: { only: [:id, :contact_name, :mobile, :decision_maker] },
          person_met_contact: { only: [:id, :contact_name, :mobile, :decision_maker] },
          user: { only: [:id, :username] },
          school: { only: [:id, :name] },
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
    def authorize_sales_executive
      unless current_user&.role == 'sales_executive'
        render json: { error: 'Only sales executives can create daily statuses.' }, status: :forbidden
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
        :user_id, :opportunity_id, :follow_up, :designation, :mail_id,
        :discussion_point, :next_steps, :stage, :decision_maker_contact_id,
        :person_met_contact_id, :school_id, :status
      )
    end
  end
end
