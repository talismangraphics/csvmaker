require 'csv'

class Admin::DashboardController < ShopifyApp::AuthenticatedController
  # GET /admin
  # GET /admin.json
  def index
    @products = ShopifyAPI::Product.find(:all, :params => {:limit => 10})
    @googlecsv = GoogleOutput

  end
end

class CsvExport
  include ActiveModel::AttributeMethods

  def initialize(collection, attributes=[])
    @collection, @attributes = collection, attributes
  end

  def generate
    CSV.generate do |csv|
      csv << @attributes.map(&:to_s)
      @collection.each do |record|
        csv << record.attributes.values_at(@attributes)
      end
    end
  end
end

  class GoogleOutput
	def initialize(collection, attributes=[])
      @collection, @attributes = collection, attributes
    end  
	    
    def create
      send_data CsvExport.new(@collection, @attributes).generate, filename: "google-productlist-#{Date.today}.csv"
    end

  end

  class LineItem
    include ActiveModel::AttributeMethods

	@id = "Maybe"
	@title = "This works"

    def self.to_csv
	  CsvExport.new(LineItem, [:id, :title]).generate
    end
    
    def all
	    id = @id
	    title = @title
	end
  end
  
  class Entry
	  
	@id = "Hello"
	@title = "How are you"
	  
  end