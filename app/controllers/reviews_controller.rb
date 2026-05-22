class ReviewsController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    @reviews = Review.approved.includes(:user).order(created_at: :desc)
    average = Review.approved.average(:rating)
    @average_rating = average ? average.round(1) : nil
    @total_reviews = Review.approved.count
  end

  def new
    @review = Review.new
  end

  def create
    @review = current_user.reviews.build(review_params)

    if @review.save
      redirect_to reviews_path, notice: "Avis en attente de modération"
    else
      flash.now[:alert] = @review.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @review = Review.find(params[:id])

    unless current_user&.id == @review.user_id
      redirect_to reviews_path, alert: "Non autorisé"
    end
  end

  def update
    @review = Review.find(params[:id])

    unless current_user&.id == @review.user_id
      redirect_to reviews_path, alert: "Non autorisé"
      return
    end

    if @review.update(review_params)
      redirect_to reviews_path, notice: "Avis mis à jour"
    else
      flash.now[:alert] = @review.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review = Review.find(params[:id])

    unless current_user&.id == @review.user_id || current_user&.role == "admin"
      redirect_to reviews_path, alert: "Non autorisé"
      return
    end

    @review.destroy
    redirect_to reviews_path, notice: "Avis supprimé"
  end

  private

  def review_params
    permitted = [ :comment, :rating ]
    permitted << :product_id if Review.column_names.include?("product_id")
    params.require(:review).permit(*permitted)
  end
end
