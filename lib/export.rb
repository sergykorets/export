class Export
  def self.export_to_csv(response, objects, chains, options = {})
    response.headers['X-Accel-Buffering'] = 'no'
    response.headers["Cache-Control"] ||= "no-cache"
    response.headers.delete("Content-Length")
    response.headers['Last-Modified'] = Time.now.to_s
    response.headers["Content-Type"] = "application/octet-stream"
    response.headers["Content-Disposition"] = "attachment; filename=\"#{options[:file_name]}_#{Date.today.strftime('%Y_%m_%d')}.csv"
    Enumerator.new do |y|
      y.yield "#{[0xef, 0xbb, 0xbf].pack('CCC').force_encoding('UTF-8')}#{options[:csv_header].to_csv(col_sep: ';')}"
      objects.find_each do |obj|
        obj_data = []
        chains.each do |chain|
          obj_data << self.send_chain(obj, chain)
        end
        y.yield obj_data.to_csv(col_sep: ";")
      end
    end
  end

  def self.send_chain(obj, chain)
    info ||= chain.values.flatten(1).inject(obj) do |o, a|
      if chain.key?(:try)
        if a.is_a?(Hash)
          o.send(a.keys.last, a.values.last)
        elsif a.is_a?(Array)
          data = a.inject(obj) do |object, item|
            if item.is_a?(Hash)
              object.send(item.keys.last, item.values.last)
            else
              object.try(item)
            end
          end
          return data if data.present?
        else
          o.try(a)
        end
      elsif chain.key?(:eval_try)
        eval(a.keys.first).try(:[], obj.send(a.values.first))
      end
    end
    info || 'N.A.'
  end
end