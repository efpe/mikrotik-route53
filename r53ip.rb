require 'webrick'
require 'aws-sdk'
require 'ipaddress'

credentials = Aws::Credentials.new(
  'access_key',
  'sec_key'
)

zoneId = 'zoneid'
record = 'example.com.'
port = 8080
log_file_name = 'r53.log'

log_file = File.open log_file_name, 'a+'
log = WEBrick::Log.new log_file
alog = [[log_file, WEBrick::AccessLog::COMBINED_LOG_FORMAT],]
srv = WEBrick::HTTPServer.new :Port => port, :Logger => log, :AccessLog => alog


trap 'INT' do srv.shutdown end

srv.mount_proc '/' do |req, res|
  unless req.query.key?('ip')
    res.body = 'Missing "ip" parameters'
    res.status = 400
    next
  end

  reqIp = req.query['ip']

  unless IPAddress.valid?(reqIp)
    res.body = 'IP address is not valid'
    res.status = 400
    next
  end

  r53 = Aws::Route53::Client.new(region: 'eu-west-1', credentials: credentials)
  homeRecord = r53.list_resource_record_sets({hosted_zone_id: zoneId, start_record_name: record, max_items: 1})
  if homeRecord.resource_record_sets[0].resource_records[0].value == reqIp
    res.body = 'IP address is the same'
    next
  end

  begin
    resp = r53.change_resource_record_sets({
      hosted_zone_id: zoneId,
      change_batch: {
        comment: 'ResourceDescription',
        changes: [{
          action: 'UPSERT',
          resource_record_set: {
            name: record,
            type: 'A',
            ttl: 600,
            resource_records: [{ value: reqIp }, ],
          },
        }, ],
      },
    })
    res.body = "Success! #{resp.change_info.to_s}\n"
    print "#{resp.change_info}\n"
    next

  rescue Aws::Route53::Errors::ServiceError => e
    res.body "Server side problem: #{e}"
    res.status = 500
    next
  end

  res.body = 'Unknown error.'
  res.status = 500
end

# Comment this out if you want to run this as a daemon.
# WEBrick::Daemon.start
srv.start
