class GoogleDirections
  def initialize(origin, destination, opts=@@default_options)
      @origin = origin
      @destination = destination
      long_lat = opts[:long_lat]
      opts = opts.merge({:origin => @origin, :destination => @destination}) unless long_lat
      @options = opts


      @url = @@base_url + '?' + @options.to_query
      @url += "&origin=#{origin}&destination=#{destination}" if long_lat
      @xml = open(@url).read
      @doc = Nokogiri::XML(@xml)
      @status = @doc.css('status').text
    end
end