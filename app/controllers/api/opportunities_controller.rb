require 'csv'
require 'roo'

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

    # Filter the response to include all required fields
    filtered_opportunities = opportunities.map do |opportunity|
      {
        id: opportunity.id,
        school_id: opportunity.school_id,
        product_id: opportunity.product_id,
        user_id: opportunity.user_id,
        contact_id: opportunity.contact_id,
        start_date: opportunity.start_date,
        opportunity_name: opportunity.opportunity_name,
        last_stage: opportunity.last_stage,
        created_at: opportunity.created_at,
        updated_at: opportunity.updated_at,
        is_active: opportunity.is_active,
        zone: opportunity.zone,
        product: {
          id: opportunity.product.id,
          product_name: opportunity.product.product_name,
          description: opportunity.product.description,
          available_days: opportunity.product.available_days
        },
        school: {
          id: opportunity.school.id,
          name: opportunity.school.name
        },
        user: {
          id: opportunity.user.id,
          username: opportunity.user.username,
          role: opportunity.user.role
        }
      }
    end

    render json: filtered_opportunities, status: :ok
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

    imported_opportunities = []

    begin
      ActiveRecord::Base.transaction do
        if file.content_type == 'text/csv'
          # Process CSV file
          CSV.foreach(file.path, headers: true) do |row|
            process_opportunity_data(row.to_h, imported_opportunities)
          end
        elsif file.content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          # Process XLSX file using Roo
          spreadsheet = Roo::Spreadsheet.open(file.path)
          headers = spreadsheet.row(1) # Extract headers from the first row

          spreadsheet.each_with_index do |row, index|
            next if index == 0 # Skip the header row
            opportunity_data = headers.zip(row).to_h
            process_opportunity_data(opportunity_data, imported_opportunities)
          end
        end
      end

      render json: { message: 'Opportunities imported successfully', opportunities: imported_opportunities }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "Error importing data: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end


  private


  # Process each opportunity row
  def process_opportunity_data(data, imported_opportunities)
    data.symbolize_keys!

    # Find related entities
    school = School.find_by(id: data[:school_id]) || raise(ActiveRecord::Rollback, "School with ID #{data[:school_id]} not found")
    product = Product.find_by(id: data[:product_id]) || raise(ActiveRecord::Rollback, "Product with ID #{data[:product_id]} not found")
    user = User.find_by(id: data[:user_id]) || current_user
    contact = Contact.find_by(id: data[:contact_id]) if data[:contact_id].present?

    # Create or update the opportunity
    opportunity = Opportunity.find_or_initialize_by(
      opportunity_name: data[:opportunity_name],
      school_id: data[:school_id],
      product_id: data[:product_id],
      user_id: data[:user_id]
    )
    opportunity.assign_attributes(
      start_date: data[:start_date],
      last_stage: data[:last_stage],
      is_active: data[:is_active],
      zone: data[:zone],
      contact_id: contact&.id,
      createdby_user_id: current_user.id,
      updatedby_user_id: current_user.id
    )
    opportunity.save!
    imported_opportunities << opportunity
  end

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
