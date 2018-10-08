require 'csv'
require 'csvmaker'

class Admin::ProductsController < ShopifyApp::AuthenticatedController
  def index
    @products = ShopifyAPI::Product.find(:all, :params => {:page => 4, :limit => 50}, :select => "id, handle, title, body_html, tags, vendor, product_type")
    @selection = "id, handle, title, body_html, tags, vendor, metafields, product_type, images"
	@header = %w{item_group_id id title description brand mpn price weight link image_link condition product_type availability gtin google_product_category}

    respond_to do |format|
      format.html
      format.csv do
        self.response_body = CsvBuilder.new(@header, "products", @selection ).build
      end
      #format.csv { send_data CsvEntry.to_csv, filename: "products-#{Date.today}.csv" }
    end
  end
  
  private def csv_filename
    "testenumerator-#{Time.zone.now.to_date.to_s(:default)}.csv"
  end	
end

