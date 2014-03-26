class DocsplitWorker
  include Sidekiq::Worker
  sidekiq_options :retry => true, :backtrace => true

  # 不成功任务记录
  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(attach_id)
    attach = Attach.find(attach_id)
    Sidekiq.logger.info "#{Time.now}: #{attach.file} "
    cache_path = Rails.root.join('public', 'uploads', 'tmp', attach.cache_id).to_s
    if Dir.exist?(cache_path) then
      Dir.foreach(cache_path) do |item|
        next if item == '.' or item == '..'
        extract_path = cache_path + "/" + item
        Docsplit.extract_images(extract_path, :size => %w{1000x}, :format => :png, output: cache_path)
        File.delete(extract_path)
      end
      Dir.foreach(cache_path) do |item|
        next if item == '.' or item == '..'
        photo = attach.photos.new
        photo.order_number = item
        photo.image = File.open(cache_path + "/" + item)
        photo.save
        attach.photo_count += 1
        FileUtils.rm(cache_path + "/" + item)
      end
      attach.save
      Dir.rmdir(cache_path)
    end
  end
end
