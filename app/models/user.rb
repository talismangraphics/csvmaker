class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  def self.to_csv
    CSV.generate do |csv|
      csv << %w{ id email score } 
      all.each do |user|
        csv << [user.id, user.email, user.score ) ]
      end
    end
  end

  def csv
   CSV.generate do |csv|
     csv << %w{ user_id user_email user_score }
     csv << [ self.id, self.email, self.score]
   end
 end
end
