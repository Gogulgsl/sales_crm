class Api::ProductsController < ApplicationController
  before_action :set_product, only: [:show, :update, :destroy]
  # before_action :authorize_user, except: [:index, :show, :my_opportunities, :create]

  # GET /api/products
  def index
    @products = Product.all
    render json: @products
  end

  # GET /api/products/:id
  def show
    render json: @product
  end

  # POST /api/products
  def create
    @product = Product.new(product_params)
    
    if @product.save
      render json: @product, status: :created, location: api_product_url(@product)
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  def active_products
    products = Product.where(is_active: true)
    render json: products
  end

  # PUT /api/products/:id
  def update
    if @product.update(product_params)
      render json: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/products/:id
  def destroy
    @product.destroy
    head :no_content
  end

  private
    # Set the product for the actions that need it
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def product_params
      params.require(:product).permit(:product_name, :description, :supplier, :unit, :price, :date, :is_active, available_days: [])
    end

  #   def authorize_user
  #   render json: { error: 'Unauthorized' }, status: :unauthorized unless request.headers['Authorization'].present?
  # end
end
