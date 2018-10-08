class CsvBuilder
 
  attr_accessor :output, :header, :data, :selectors

  def initialize(header, data, selectors, output = "")
    @output = output
    @header = header
    @data = data
    @selectors = selectors
  end

  def build
	
	filename = "testbg-#{Date.today}.csv"
	
	selecting = "id, handle, title, body_html, tags, vendor, metafields, product_type, images"
	
	CSV.open("#{Rails.root}/public/docs/"+ filename, "w") do |csv|
      csv << %w{item_group_id id title description brand mpn price weight link image_link condition product_type availability gtin google_product_category}

	  grog = 1
	    
	  until grog == 3
	    minedata = ShopifyAPI::Product.find(:all, :params =>{:page => grog, :limit => 50}, :select => selecting)
        unless minedata.empty?
	
        shop_url = ShopifyAPI::Shop.current.domain      
	      
          minedata.each do |row|
	      
	        next if row.tags.include? "not-in-feed"

		    pass_title = row.metafields("namespace": "c_f","key": "short_title")
		
		    variants = ShopifyAPI::Variant.find(:all, 
		    :params=>{
		  	  :product_id => row.id, 
			  :order => "position", 
			  :fields => "id, sku, barcode, price, weight, weight_unit, position, image_id"
			  })
		
		    variants.each do |variant|
			  
              csv << [
                row.id, 
                variant.id, 
                custom_title(row,variant.sku,pass_title), 
                clean_desc(row.body_html),
                row.vendor, 
                variant.sku,
                variant.price + " USD",
                variant.weight.to_s + " " + variant.weight_unit,
                item_link(variants.count,shop_url,row.handle,variant.id),
                item_image(row,variant.image_id),
                "new",
                row.product_type,
                "in stock",
                variant.barcode,
                "Hardware > Hardware Accessories > Door Hardware"
                ]
            
            end
          end
        end
        grog += 1
      end
    end
  end
  
  def clean_desc(body)
    newhtml = ActionController::Base.helpers.strip_tags(body)
		
	unless newhtml.length > 250
	  goog_desc = newhtml
	end
	if newhtml.length > 250
	  unless newhtml[250..-1].index(".").to_s.empty?
	    sentence_index = 251 + newhtml[250..-1].index(".")
        goog_desc = newhtml[0,sentence_index]
   	  end
	  if newhtml[250..-1].index(".").to_s.empty?
        goog_desc = newhtml
	  end
	end
	goog_desc  
  end 
  
  def custom_title(row,mpn,title_end)
	unless title_end.empty?
	  customized_title = row.vendor + " " + mpn + " " + title_end.first.value
	end	
	if title_end.empty? 
	  customized_title = row.title
	end
	customized_title  
  end  
  
  def item_link(v_count,shop_url,handle,v_id)
	unless v_count >1 
      item_link = "http://" + shop_url + "/products/" + handle
    end
	if v_count >1 
	  item_link = "http://" + shop_url + "/products/" + handle + "?variant=" + v_id.to_s
	end
	item_link
  end 
  
  def item_image(row,v_image_id)
	g_image_link = ""
	unless row.tags.include? "use-main-image"
	  unless v_image_id.blank?
	    g_image_link = row.images.find(:id => v_image_id).first.src
	  end
	end
	if row.tags.include? "use-main-image"	      
	  unless row.images.find(:position => "1").first.exists?  
	    g_image_link = row.images.find(:position => "1").first.src	
	  end	  	
	end
	g_image_link    
  end
end

class CsvEntry
  
  def initialize 
  end
  
  def self.products
  	products = ShopifyAPI::Product.find(
  	  :all, 
  	  :params => {:limit => 10}, 
  	  :select => "body_html, handle, id, tags, title, variants, metafields")
  end

  def build_csv_enumerator(header, data)
    Enumerator.new do |y|
      CsvBuilder.new(header, data, y)
    end
  end
  
  
#old version
  def self.to_csv
    attributes = %w{item_group_id id title availability brand description google_product_category gtin image_link link mpn condition price product_type shipping_weight} #customize columns here
 

    CSV.generate(headers: true) do |csv|
      csv << attributes

	  shop_url = ShopifyAPI::Shop.current.domain
	  cst_compare = []
	  cst_collect = ShopifyAPI::CustomCollection.find(:all, :select => "id")
	  cst_collect.each do |cst_connect|
		cst_compare.push(cst_connect.id)
	  end
	  
	  products.each do |product|
		
		next if product.tags.include? "not-in-feed"
		
		con_compare = []
		con_collect = ShopifyAPI::Collect.find(:all, :params => {:product_id => product.id}, :select => "collection_id")
		con_collect.each do |con_connect|
			con_compare.push(con_connect.collection_id)
		end
		
		col_check = cst_compare & con_compare
		
		mfrefer = ""
		title_mf = ""
		title_end = ""
		brand_name = ""
		goog_cat = ""
		goog_desc = ""
		p_image_link = ""
		newhtml = ""
		sentence_index = ""
	    vendors = %w(cal-royal von-duprin stanley-best avanti-guardian adams-rite)

		
		if product.metafields("namespace": "c_f").any?
			if product.metafields("namespace": "c_f","key": "manufacturer").any?				
			  mfrefer = product.metafields("namespace": "c_f","key": "manufacturer").first.value
			  title_mf = ShopifyAPI::CustomCollection.find(:all, :params => {:handle => mfrefer}, :select => "handle, title").first.title
			end
			if product.metafields("namespace": "c_f","key": "short_title").any?
			  title_end = product.metafields("namespace": "c_f","key": "short_title").first.value
			end
		end
		
		col_check.each do |quickcheck|
		  handle_hold = ShopifyAPI::CustomCollection.find(quickcheck)
		  if vendors.include? handle_hold.handle
			brand_name = handle_hold.title
		  end
		end	
		
		if product.metafields("key": "google_product_type").any?
		goog_cat = product.metafields("namespace": "google","key": "google_product_type").first.value
		else
		goog_cat = "Hardware > Hardware Accessories > Door Hardware"
		end
		
		if product.metafields("key": "description_tag").any?
		goog_desc = product.metafields("namespace": "global","key": "description_tag").first.value
		else
		  newhtml = ActionController::Base.helpers.strip_tags(product.body_html)
		  sentence_index = 251 + newhtml[250..-1].index(".")
		  goog_desc = newhtml[0,sentence_index]
		end
		
		if product.images.find(:any).any?
		  p_image_link = product.images.find(:position => "1").first.src
		end
		
	  	variants = product.variants

	    variants.each do |entry|
		
		item_link = ""
		custom_title = ""
		goog_price = ""
		goog_weight = ""
		v_image_link = ""
		goog_gtin = ""
		goog_image = ""
		
		goog_price = entry.price + " USD"
		goog_weight = entry.weight.to_s + " lbs"
		
		if title_mf.empty? || title_end.empty? 
		custom_title = product.title
		else
		custom_title = title_mf + " " + entry.sku + " " + title_end
		end
		
		if product.variants.count >1 
		  item_link = "http://" + shop_url + "/products/" + product.handle + "?variant=" + entry.id.to_s
		else
		  item_link = "http://" + shop_url + "/products/" + product.handle
		end
		
		if entry.barcode?
		  goog_gtin = entry.barcode
		end
		
		if entry.image_id?
			v_image_link = product.images.find(:id => entry.image_id).first.src
		end
		
		if v_image_link.empty?
			goog_image = p_image_link
		else
			goog_image = v_image_link
		end
			
	
		
		csvfields = CsvGrouping.new
		csvfields.assign_stuff( "availability", "in stock" )
		csvfields.assign_stuff( "id", entry.id.to_s )
		csvfields.assign_stuff( "title", custom_title )
		csvfields.assign_stuff( "item_group_id", product.id.to_s )
		csvfields.assign_stuff( "brand", brand_name )
		csvfields.assign_stuff( "description", goog_desc )
		csvfields.assign_stuff( "google_product_category", goog_cat )
		csvfields.assign_stuff( "gtin", goog_gtin )
		csvfields.assign_stuff( "image_link", goog_image )
		csvfields.assign_stuff( "link", item_link )
		csvfields.assign_stuff( "mpn", entry.sku )
		csvfields.assign_stuff( "condition", "new" )
		csvfields.assign_stuff( "price", goog_price )
		csvfields.assign_stuff( "product_type", goog_cat )
		csvfields.assign_stuff( "shipping_weight", goog_weight )
		
		
          csv << attributes.map{ |attr| csvfields.send(attr ) }
        end
      end 
    end
  end

end

class CsvGrouping < CsvEntry

  def initialize 
	@id = "1234"
	@title = "Test Title"
	@availability = "not in stock"
	@item_group_id = ""
	@brand = ""
    @description = "" 
    @google_product_category = ""
    @gtin = ""
    @image_link = ""
    @link = ""
    @mpn = ""
    @condition = ""
    @price = ""
    @product_type = ""
    @shipping_weight = ""
  end
  
  def id
    @id
  end
  
  def title
    @title
  end
  
  def availability
    @availability
  end
  
  def item_group_id
    @item_group_id
  end

  def brand
    @brand
  end

  def description
    @description
  end

  def google_product_category
    @google_product_category
  end

  def gtin
    @gtin
  end

  def image_link
    @image_link
  end

  def link
    @link
  end

  def mpn
    @mpn
  end

  def condition
    @condition
  end
  
  def price
    @price
  end

  def product_type
    @product_type
  end
  
  def shipping_weight
    @shipping_weight
  end  
                  
  def assign_stuff(attr_name, value)
  	if attr_name == "availability"
	@availability = value
	end
	if attr_name == "id"
	@id = value
	end
    if attr_name == "title"
	@title = value
	end
	if attr_name == "item_group_id"
	@item_group_id = value
	end
	if attr_name == "brand"
	@brand = value
	end  
	if attr_name == "description"
	@description = value
	end
	if attr_name == "google_product_category"
	@google_product_category = value
	end
	if attr_name == "gtin"
	@gtin = value
	end
	if attr_name == "image_link"
	@image_link = value
	end	
	if attr_name == "link"
	@link = value
	end
	if attr_name == "mpn"
	@mpn = value
	end
	if attr_name == "condition"
	@condition = value
	end
	if attr_name == "price"
	@price = value
	end
	if attr_name == "product_type"
	@product_type = value
	end
	if attr_name == "shipping_weight"
	@shipping_weight = value
	end
  end
  
end
