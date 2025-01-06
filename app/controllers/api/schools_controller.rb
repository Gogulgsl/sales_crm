require 'csv'
require 'roo'

class Api::SchoolsController < ApplicationController
  before_action :set_school, only: %i[show edit update destroy contacts update_contacts]
  before_action :authorize_user, except: [:show, :active_schools]
  before_action -> { authorize_role('admin', 'sales_executive', 'sales_head', 'vp_sales') }, only: [:index]

  # GET /schools
  def index
    if current_user.role == 'admin' || current_user.role == 'vp_sales'
      schools = School.includes(:group_school).all
    elsif current_user.role == 'sales_head'
      reporting_users = User.where(reporting_manager_id: current_user.id).pluck(:id)
      relevant_user_ids = [current_user.id] + reporting_users
      schools = School.includes(:group_school).where(id: Opportunity.where(user_id: relevant_user_ids).pluck(:school_id))
    elsif current_user.role == 'sales_executive'
      schools = School.includes(:group_school).where(id: Opportunity.where(user_id: current_user.id).pluck(:school_id))
    else
      schools = []
    end

    render json: schools.map { |school| format_school_data(school) }, status: :ok
  end

  # GET /schools/:id
  def show
    render json: format_school_data(@school)
  end

  # POST /schools
  def create
    ActiveRecord::Base.transaction do
      # Ensure the group school is handled when part_of_group_school is true
      if params[:school][:part_of_group_school] && params[:school][:group_school_id].blank?
        render json: { error: 'Group school must be provided if the school is part of a group' }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end

      # Find or create group school if part_of_group_school is true and group_school_id is provided
      group_school = nil
      if params[:school][:part_of_group_school]
        group_school = School.find_by(id: params[:school][:group_school_id])
        if group_school.nil?
          render json: { error: 'Group school not found' }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end
      end

      # Create the school with provided params, including group_school_id if applicable
      @school = School.new(school_params.merge(group_school_id: group_school&.id))

      if @school.save
        # If contacts data is provided, create or update the contacts for the school
        contacts = if params[:school][:contacts].present?
                     create_or_update_contacts(params[:school][:contacts], @school.id)
                   else
                     []
                   end

        # Return school data along with contacts
        render json: { school: format_school_data(@school), contacts: contacts }, status: :created
      else
        render json: { errors: @school.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH/PUT /schools/:id
  def update
    ActiveRecord::Base.transaction do
      if params[:school][:part_of_group_school] && params[:school][:group_school_id].blank?
        group_school = create_or_find_group_school(params[:school][:group_school])
        params[:school][:group_school_id] = group_school.id
      end

      if @school.update(school_params)
        contacts = create_or_update_contacts(params[:school][:contacts], @school.id) if params[:school][:contacts]
        render json: { school: format_school_data(@school), contacts: contacts }, status: :ok
      else
        render json: { errors: @school.errors.full_messages }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /schools/:id
  def destroy
    @school.destroy
    head :no_content
  end

  # GET /schools/head_quarters
  def head_quarters
    schools = School.includes(:group_school).where(part_of_group_school: false)

    if schools.any?
      render json: schools.map { |school| format_school_data(school) }, status: :ok
    else
      render json: { message: 'No head_quarters found' }, status: :not_found
    end
  end

  # GET /schools/:id/contacts
  def contacts
    contacts = @school.contacts.select(:id, :contact_name, :mobile, :decision_maker, :designation)
    if contacts.any?
      render json: contacts, status: :ok
    else
      render json: { message: 'No contacts found for this school' }, status: :not_found
    end
  end

  # PATCH /schools/:id/contacts
  def update_contacts
    if params[:contacts].blank?
      render json: { error: 'No contacts data provided' }, status: :unprocessable_entity
      return
    end

    updated_contacts = create_or_update_contacts(params[:contacts], @school.id)
    render json: { message: 'Contacts updated successfully', contacts: updated_contacts }, status: :ok
  end

  # GET /schools/active_schools
  def active_schools
    schools = School.includes(:group_school).where(is_active: true)

    if schools.any?
      render json: schools.map { |school| format_school_data(school) }, status: :ok
    else
      render json: { message: 'No active schools found' }, status: :not_found
    end
  end

  def import_file
    if params[:file].blank?
      render json: { error: 'No file provided' }, status: :unprocessable_entity
      return
    end

    file = params[:file]
    if !['text/csv', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'].include?(file.content_type)
      render json: { error: 'Invalid file format. Please upload a CSV or XLSX file.' }, status: :unprocessable_entity
      return
    end

    imported_schools = []

    begin
      ActiveRecord::Base.transaction do
        if file.content_type == 'text/csv'
          # Handle CSV files
          CSV.foreach(file.path, headers: true) do |row|
            process_school_data(row.to_h, imported_schools)
          end
        elsif file.content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          # Handle XLSX files using Roo
          spreadsheet = Roo::Spreadsheet.open(file.path)
          headers = spreadsheet.row(1) # Get the header row

          spreadsheet.each_with_index do |row, index|
            next if index == 0 # Skip the header row

            # Convert row to a hash using the headers
            school_data = headers.zip(row).to_h

            process_school_data(school_data, imported_schools)
          end
        end
      end

      render json: { message: 'Schools and contacts imported successfully' }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "Error importing data: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  # Modify the process_school_data method to accept imported_schools as an argument
  def process_school_data(school_data, imported_schools)
    school_data.symbolize_keys!

    # Find the group school if provided
    group_school = nil
    if school_data[:part_of_group_school] && school_data[:group_school_id]
      group_school = School.find_by(id: school_data[:group_school_id])
      raise ActiveRecord::Rollback, "Group school with ID #{school_data[:group_school_id]} not found" unless group_school
    end

    # Create or update the school record
    school = School.find_or_initialize_by(name: school_data[:name], email: school_data[:email])
    school.assign_attributes(school_data.except(:contacts).merge(group_school_id: group_school&.id))
    school.createdby_user_id = current_user.id
    school.updatedby_user_id = current_user.id
    school.save!

    # Parse and create/update contacts if present
    if school_data[:contacts].present?
      begin
        contacts = JSON.parse(school_data[:contacts], symbolize_names: true)
        contacts.each do |contact_data|
          contact = school.contacts.find_or_initialize_by(mobile: contact_data[:mobile])
          contact.assign_attributes(contact_data.merge(
            school_id: school.id,
            createdby_user_id: current_user.id,
            updatedby_user_id: current_user.id
          ))
          contact.save!
        end
      rescue JSON::ParserError => e
        raise ActiveRecord::Rollback, "Invalid JSON format in contacts: #{e.message}"
      end
    end
    imported_schools << school
  end

  

  def set_school
    @school = School.find_by(id: params[:id])
    render json: { error: 'School not found' }, status: :not_found unless @school
  end

  def school_params
    params.require(:school).permit(
      :name, :email, :lead_source, :location, :city, :state, :pincode,
      :number_of_students, :avg_fees, :board, :website, :part_of_group_school,
      :group_school_id, :createdby_user_id, :updatedby_user_id, :latitude,
      :longitude, :is_active, contacts_attributes: [:contact_name, :mobile, :decision_maker, :designation]
    )
  end

  def create_or_update_contacts(contacts_params, school_id)
    contacts_params.map do |contact_data|
      # Look for an existing contact by mobile
      existing_contact = Contact.find_by(mobile: contact_data[:mobile])

      if existing_contact
        # Update contact details and associate with the correct school_id
        existing_contact.update!(
          contact_name: contact_data[:contact_name],
          decision_maker: contact_data[:decision_maker],
          designation: contact_data[:designation],
          school_id: school_id 
        )
        existing_contact
      else
        # Create a new contact if it doesn't exist
        Contact.create!(
          contact_name: contact_data[:contact_name],
          mobile: contact_data[:mobile],
          decision_maker: contact_data[:decision_maker],
          designation: contact_data[:designation],
          school_id: school_id
        )
      end
    end
  end

  def create_or_find_group_school(group_school_params)
    return unless group_school_params

    School.find_or_create_by!(name: group_school_params[:name]) do |school|
      school.assign_attributes(group_school_params.except(:name))
    end
  end

  def format_school_data(school)
    school.as_json.merge({
      group_school: school.group_school ? school.group_school.slice(:id, :name) : {},
      contacts: school.contacts.select(:id, :contact_name, :mobile, :decision_maker, :designation)
    })
  end

  def authorize_user
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: decoded_token&.dig('user_id'))
  end
end
