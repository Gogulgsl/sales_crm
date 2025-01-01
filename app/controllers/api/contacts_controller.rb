module Api
  class ContactsController < ApplicationController
    before_action :set_contact, only: %i[show edit update destroy]

    # GET /contacts
    def index
      @contacts = Contact.all
      render json: @contacts
    end

    # GET /contacts/:id
    def show
    end

    # GET /contacts/new
    def new
      @contact = Contact.new
    end

    # POST /contacts
    def create
      @contact = Contact.new(contact_params)
      @contact.createdby_user_id = current_user.id # Assuming you have `current_user`

      if @contact.save
        render json: @contact, status: :created
      else
        render json: @contact.errors, status: :unprocessable_entity
      end
    end

    def active_contacts
      contacts = Contact.where(is_active: true)
      render json: contacts
    end

    # GET /contacts/:id/edit
    def edit
    end

    # PATCH/PUT /contacts/:id
    def update
      @contact.updatedby_user_id = current_user.id # Assuming you have `current_user`

      if @contact.update(contact_params)
        redirect_to @contact, notice: 'Contact was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /contacts/:id
    def destroy
      @contact.destroy
      redirect_to contacts_url, notice: 'Contact was successfully deleted.'
    end

    private

    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.require(:contact).permit(:contact_name, :mobile, :decision_maker, :school_id)
    end
  end
end
