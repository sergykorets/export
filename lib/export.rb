class Export

  def initialize(options = {})
    @file_name  = options[:file_name]
    @csv_header = options[:csv_header]
    @response   = options[:response]
    @objects    = options[:objects]
  end

  def export_to_csv
    @response.headers['X-Accel-Buffering'] = 'no'
    @response.headers["Cache-Control"] ||= "no-cache"
    @response.headers.delete("Content-Length")
    @response.headers['Last-Modified'] = Time.now.to_s
    @response.headers["Content-Type"] = "application/octet-stream"
    @response.headers["Content-Disposition"] = "attachment; filename=\"#{@file_name}_#{Date.today.strftime('%Y_%m_%d')}.csv"
    Enumerator.new do |y|
      y.yield "#{[0xef, 0xbb, 0xbf].pack('CCC').force_encoding('UTF-8')}#{@csv_header.to_csv(col_sep: ';')}"
      @objects.each { |o| y.yield yield(o).to_csv(col_sep: ';') }
    end
  end
end