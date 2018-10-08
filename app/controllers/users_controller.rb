class UsersController < ApplicationController
  def index
    @users = User.all.order(:id)
    respond_to do |format|
      format.html
      format.csv { send_data @users.to_csv, filename: "users-#{Date.today}.csv" }
    end
  end
  
  def show
   @user = User.find(params[:id])
   respond_to do |format|
       format.html
       format.csv { send_data @user.csv, filename: "#{@user.email}-donations-#{Date.today}.csv" }
   end
  end
end