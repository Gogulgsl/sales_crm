class Api::AuthController < ApplicationController
  require 'jwt'

  def login
    user = User.find_by(username: params[:username])

    if user.nil?
      render json: { error: 'Invalid username or password' }, status: :unauthorized
    elsif !user.is_active
      render json: { error: 'Current user is not active' }, status: :unauthorized
    elsif user.authenticate(params[:password])
      token = encode_token({ user_id: user.id })

      render json: { token: token, role: user.role, username: user.username, message: "Login successful #{user.username}" }, status: :ok
    else
      render json: { error: 'Invalid username or password' }, status: :unauthorized
    end
  end
end
