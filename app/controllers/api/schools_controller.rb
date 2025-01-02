class Api::SchoolsController < ApplicationController
  before_action :set_school, only: %i[show edit update destroy contacts update_contacts]
  before_action :authorize_user, except: [:index, :show, :active_schools]
  before_action -> { authorize_role('admin', 'sales_executive') }, only: [:index]

  # GET /schools
  def index
    schools = if current_user.role == 'admin'
                School.includes(:group_school).all
              elsif current_user.role == 'sales_executive'
                School.includes(:group_school).where(is_active: true)
              else
                []
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
      group_school = find_or_create_group_school(params[:school][:group_school]) if params[:school][:group_school]

      if @school.update(school_params.merge(group_school_id: group_school&.id))
        contacts = create_or_update_contacts(params[:school][:contacts], @school.id) if params[:school][:contacts]
        render json: { school: @school, contacts: contacts }, status: :ok
      else
        render json: { errors: @school.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
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
    contacts = @school.contacts.select(:id, :contact_name, :mobile, :decision_maker)
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

  private

  def set_school
    @school = School.find_by(id: params[:id])
    render json: { error: 'School not found' }, status: :not_found unless @school
  end

  def school_params
    params.require(:school).permit(
      :name, :email, :lead_source, :location, :city, :state, :pincode,
      :number_of_students, :avg_fees, :board, :website, :part_of_group_school,
      :group_school_id, :createdby_user_id, :updatedby_user_id, :latitude,
      :longitude, :is_active, contacts_attributes: [:contact_name, :mobile, :decision_maker]
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
          school_id: school_id # Ensure the contact is associated with the correct school
        )
        existing_contact
      else
        # Create a new contact if it doesn't exist
        Contact.create!(
          contact_name: contact_data[:contact_name],
          mobile: contact_data[:mobile],
          decision_maker: contact_data[:decision_maker],
          school_id: school_id
        )
      end
    end
  end

  def find_or_create_group_school(group_school_params)
    return unless group_school_params

    School.find_or_create_by!(name: group_school_params[:name]) do |school|
      school.assign_attributes(group_school_params.except(:name))
    end
  end

  def format_school_data(school)
    school.as_json.merge({
      group_school: school.group_school ? school.group_school.slice(:id, :name) : {},
      contacts: school.contacts.select(:id, :contact_name, :mobile, :decision_maker)
    })
  end

  def authorize_user
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: decoded_token&.dig('user_id'))
  end
end
