require 'csv'
require 'roo'

module Api
  class DailyStatusesController < ApplicationController
    before_action :set_daily_status, only: [:show, :edit, :update, :destroy]
    before_action :authorize_sales_executive_or_head, only: [:create]
    before_action :authorize_admin, only: [:update]

    # GET /daily_statuses
    def index
      @daily_statuses = if current_user.role.in?(%w[admin vp_sales])
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product).all
                        elsif current_user.role == 'sales_head'
                          reporting_users = SalesTeam.where(manager_user_id: current_user.id).pluck(:user_id)
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product)
                                     .where(user_id: [current_user.id] + reporting_users)
                        elsif current_user.role == 'sales_executive'
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product)
                                     .where(user_id: current_user.id)
                        else
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
        },
        methods: [:createdby_username] # Include the salesperson's name
      )
    end

    def pagination
      per_page = params[:per_page] || 500
      @daily_statuses = if current_user.role.in?(%w[admin vp_sales])
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product)
                                     .page(params[:page]).per(per_page)
                        elsif current_user.role == 'sales_head'
                          reporting_users = SalesTeam.where(manager_user_id: current_user.id).pluck(:user_id)
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product)
                                     .where(user_id: [current_user.id] + reporting_users)
                                     .page(params[:page]).per(per_page)
                        elsif current_user.role == 'sales_executive'
                          DailyStatus.includes(:decision_maker_contact, :person_met_contact, :user, :school, opportunity: :product)
                                     .where(user_id: current_user.id)
                                     .page(params[:page]).per(per_page)
                        else
                          return render json: { error: 'Unauthorized access' }, status: :forbidden
                        end

      render json: {
        data: @daily_statuses.as_json(
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
          },
          methods: [:createdby_username] # Include the salesperson's name
        ),
        current_page: @daily_statuses.current_page,
        total_pages: @daily_statuses.total_pages,
        total_count: @daily_statuses.total_count
      }
    end



    # GET /daily_statuses/:id
    def show
      render json: @daily_status.as_json(
        include: {
          decision_maker_contact: { only: [:id, :contact_name, :mobile, :decision_maker] },
          person_met_contact: { only: [:id, :contact_name, :mobile, :decision_maker] }
        },
        methods: [:createdby_username] # Include the salesperson's name
      )
    end

    # POST /daily_statuses
    def create
      @daily_status = DailyStatus.new(daily_status_params)
      @daily_status.createdby_user_id = current_user.id
      @daily_status.updatedby_user_id = current_user.id
      @daily_status.createdby_username = current_user.username # Store salesperson name
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

    # POST /daily_statuses/import_file
    def import_file
      if params[:file].blank?
        render json: { error: 'No file provided' }, status: :unprocessable_entity
        return
      end

      file = params[:file]
      unless ['text/csv', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'].include?(file.content_type)
        render json: { error: 'Invalid file format. Please upload a CSV or XLSX file.' }, status: :unprocessable_entity
        return
      end

      imported_dsr_records = []

      begin
        ActiveRecord::Base.transaction do
          if file.content_type == 'text/csv'
            CSV.foreach(file.path, headers: true) do |row|
              process_dsr_data(row.to_h, imported_dsr_records)
            end
          elsif file.content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            spreadsheet = Roo::Spreadsheet.open(file.path)
            headers = spreadsheet.row(1)
            spreadsheet.each_with_index do |row, index|
              next if index == 0 # Skip header row
              dsr_data = headers.zip(row).to_h
              process_dsr_data(dsr_data, imported_dsr_records)
            end
          end
        end

        render json: { message: 'Daily statuses imported successfully', records: imported_dsr_records }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: "Error importing data: #{e.message}" }, status: :unprocessable_entity
      rescue StandardError => e
        render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
      end
    end

    private

    def process_dsr_data(data, imported_dsr_records)
      data.symbolize_keys!
      user = User.find_by(id: data[:createdby_user_id]) || raise(ActiveRecord::Rollback, "User with ID #{data[:createdby_user_id]} not found")

      daily_status = DailyStatus.find_or_initialize_by(
        user_id: data[:user_id],
        opportunity_id: data[:opportunity_id],
        created_at: data[:created_at]
      )

      daily_status.assign_attributes(
        follow_up: data[:follow_up],
        designation: data[:designation],
        email: data[:email],
        discussion_point: data[:discussion_point],
        next_steps: data[:next_steps],
        stage: data[:stage],
        school_id: data[:school_id],
        decision_maker_contact_id: data[:decision_maker_contact_id],
        person_met_contact_id: data[:person_met_contact_id],
        status: data[:status] || 'pending',
        createdby_user_id: user.id,
        createdby_username: user.username, # Populate salesperson name
        updatedby_user_id: current_user.id
      )

      daily_status.save!
      imported_dsr_records << daily_status
    end

    def set_daily_status
      @daily_status = DailyStatus.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Daily status not found' }, status: :not_found
    end

    def authorize_sales_executive_or_head
      unless current_user&.role.in?(['sales_executive', 'sales_head'])
        render json: { error: 'Only sales executives and sales heads can create daily statuses.' }, status: :forbidden
      end
    end

    def authorize_admin
      if daily_status_params[:status].present? && current_user&.role != 'admin'
        render json: { error: 'Only admins can update the status.' }, status: :forbidden
      end
    end

    def daily_status_params
      params.require(:daily_status).permit(
        :user_id, :opportunity_id, :follow_up, :designation, :email,
        :discussion_point, :next_steps, :stage, :decision_maker_contact_id,
        :person_met_contact_id, :school_id, :status
      )
    end
  end
end
