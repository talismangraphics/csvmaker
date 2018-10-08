class HardWorker
  include Sidekiq::Worker

  def perform(*args)
    HardWorker.perform_async(CsvBuilder.new("what", "products", "how" ).build, 5)
  end
end
