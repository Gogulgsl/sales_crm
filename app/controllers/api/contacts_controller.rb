module Api
  class ContactsController < ApplicationController
    before_action :set_contact, only: %i[show edit update destroy]

    # GET /contacts
    def index
      # Eager load the associated school with each contact
      @contacts = Contact.includes(:school).all

      # Render contacts with school details included
      render json: @contacts.as_json(include: { school: { only: [:id, :name] } })
    end

    # GET /contacts/:id
    def show
      render json: @contact.as_json(include: { school: { only: [:id, :name] } })
    end

    # POST /contacts
    def create
      # Check if a contact with the same mobile number already exists
      existing_contact = Contact.find_by(mobile: contact_params[:mobile])

      if existing_contact
        render json: { error: "A contact with this mobile number already exists." }, status: :unprocessable_entity
      else
        @contact = Contact.new(contact_params)
        @contact.createdby_user_id = current_user&.id

        if @contact.save
          render json: @contact.as_json(include: { school: { only: [:id, :name] } }), status: :created
        else
          render json: @contact.errors, status: :unprocessable_entity
        end
      end
    end

    # GET /contacts/active_contacts
    def active_contacts
      contacts = Contact.includes(:school).where(is_active: true)
      render json: contacts.as_json(include: { school: { only: [:id, :name] } })
    end

    # PATCH/PUT /contacts/:id
    def update
      @contact.updatedby_user_id = current_user.id

      if @contact.update(contact_params)
        render json: @contact.as_json(include: { school: { only: [:id, :name] } }), status: :ok
      else
        render json: @contact.errors, status: :unprocessable_entity
      end
    end

    # DELETE /contacts/:id
    def destroy
      @contact.destroy
      head :no_content
    end

    private

    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.require(:contact).permit(:contact_name, :mobile, :decision_maker, :school_id, :designation, :is_active)
    end
  end
end
