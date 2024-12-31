class Api::UsersController < ApplicationController
  def index
    users = User.includes(:manager_user).all

    users_data = users.map do |user|
      user_data = user.as_json

      if user.role == 'sales_executive' && user.manager_user
        # Include manager details in the user response
        user_data[:manager_user] = user.manager_user.as_json(only: [:id, :username, :role]) # You can choose which fields to show
      end

      user_data
    end

    render json: users_data
  end

  def show
    user = User.find(params[:id])
    render json: user
  end

 def create
    user = User.new(user_params)
    
    if user.save
      # Set manager_user_id to nil for admin users
      manager_user_id = user.role == 'admin' ? nil : user.reporting_manager_id
      
      # Create the SalesTeam with the correct manager_user_id
      sales_team = SalesTeam.create(
        user_id: user.id,
        manager_user_id: manager_user_id, # This will be nil for admin users
        createdby_user_id: current_user&.id
      )

      if sales_team.persisted?
        Rails.logger.debug "SalesTeam created successfully: #{sales_team.inspect}"
        render json: user, status: :created
      else
        Rails.logger.debug "SalesTeam creation failed: #{sales_team.errors.full_messages}"
        render json: sales_team.errors, status: :unprocessable_entity
      end
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  def reporting_managers
    admin_and_manager_users = User.where(role: ['admin', 'manager'])

    render json: admin_and_manager_users.as_json(only: [:id, :username, :role, :created_at, :updated_at])
  end

  def update
    user = User.find(params[:id])

    if user.update(user_update_params)
      render json: user
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    head :no_content
  end

  def forgot_password
    user = User.find_by(email_id: params[:email_id]) # Or use :username depending on your app
    
    if user
      reset_token = SecureRandom.hex(10) # Generate a random reset token
      user.update(reset_password_token: reset_token, reset_password_sent_at: Time.current)

      # Return the reset token to the frontend (useful for reset form redirection)
      render json: { reset_token: reset_token, message: "Reset token generated successfully." }, status: :ok
    else
      render json: { error: "User not found." }, status: :not_found
    end
  end


  def reset_password
    token = params[:reset_token]
    new_password = params[:new_password]
    confirm_password = params[:confirm_password]

    # Find the user by the reset token
    user = User.find_by(reset_password_token: token)

    # Check if the user exists and the reset token is not expired
    if user && user.reset_password_sent_at > 2.hours.ago
      # Check if new password and confirm password match
      if new_password == confirm_password
        # Update the user's password and clear reset token
        if user.update(password: new_password, reset_password_token: nil, reset_password_sent_at: nil)
          render json: { message: "Password reset successfully." }, status: :ok
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error: "New password and confirmation password do not match." }, status: :unprocessable_entity
      end
    else
      render json: { error: "Invalid or expired reset token." }, status: :unprocessable_entity
    end
  end


  private

  def user_params
    params.require(:user).permit(:username, :password, :role, :reporting_manager_id, :email_id, :mobile_number, :is_active)
  end

  def user_update_params
    params.require(:user).permit(:username, :role, :reporting_manager_id, :email_id, :mobile_number, :is_active)
  end
end