module ActionView
  module Helpers
    def connexion_bar
      unless @connexion_bar
        service_uri = "https://www.mygcx.org/Public/module/omnibar/omnibar"
        proxy_granting_ticket = session[:cas_pgt]
        unless proxy_granting_ticket.nil?
          # raise proxy_granting_ticket.inspect
          proxy_ticket = CASClient::Frameworks::Rails::Filter.client.request_proxy_ticket(proxy_granting_ticket, service_uri).ticket
          ticket = CASClient::ServiceTicket.new(proxy_ticket, service_uri)
          uri = "#{service_uri}?ticket=#{proxy_ticket}"
          logger.debug('URI: ' + uri)
          uri = URI.parse(uri) unless uri.kind_of? URI
          https = Net::HTTP.new(uri.host, uri.port)
          https.use_ssl = (uri.scheme == 'https')
          raw_res = https.start do |conn|
            conn.get("#{uri}")
          end
          begin
            doc = REXML::Document.new(raw_res.body)
          rescue REXML::ParseException => e
            logger.debug("MALFORMED CAS RESPONSE:\n#{raw_res.inspect}\n\nEXCEPTION:\n#{e}")
            return @connexion_bar = ''
          end
          unless doc.elements && doc.elements["reportoutput"]
            logger.debug("This does not appear to be a valid connexion bar (missing reportdata element)!\nXML DOC:\n#{doc.elements.to_s}")
            return @connexion_bar = ''
          end
          @connexion_bar = doc.elements['reportoutput'].children.first.to_s
        end
      end
      return @connexion_bar
    end
  end
end