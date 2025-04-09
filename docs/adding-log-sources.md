# Adding Log Sources to SecuriWatch

This guide explains how to add additional log sources to your SecuriWatch monitoring system.

## Types of Log Sources

SecuriWatch supports several types of log sources:

1. **System logs** - syslog, auth.log, secure logs
2. **Web server logs** - Nginx, Apache
3. **Application logs** - custom application logs
4. **Docker container logs**
5. **Network device logs** - firewalls, routers, switches
6. **Cloud service logs** - AWS CloudTrail, Azure Activity logs, etc.

## Adding a New Log Source

### Method 1: Direct File Access

If you can directly access the log files on the host machine, update the Filebeat configuration to capture those logs:

1. Edit `config/filebeat/filebeat.yml`:

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /path/to/your/logfile.log
  fields:
    type: your_log_type
  fields_under_root: true
  scan_frequency: 10s
```

2. Restart Filebeat:

```bash
docker-compose restart filebeat
```

### Method 2: Remote Log Forwarding

For logs that cannot be directly accessed by Filebeat:

1. Configure your log source to forward logs to Logstash:

   a. For syslog-compatible devices:
      - Configure the device to send logs to your SecuriWatch server's IP on port 5140

   b. For applications that support direct HTTP logging:
      - Configure the application to send logs to: `http://your-server:5000`

2. Make sure the corresponding ports are open in your firewall.

### Method 3: Cloud Integrations

For cloud services:

1. Create a new integration in Logstash:

   a. Create a new pipeline file in `config/logstash/pipeline/cloud-integration.conf`:

```
input {
  http {
    port => 8085
    codec => json
  }
}

filter {
  # Add custom filtering for your cloud logs
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "cloud-logs-%{+YYYY.MM.dd}"
  }
}
```

2. Configure your cloud service to send logs to this endpoint.

## Configuring Log Parsing

To properly parse and extract security events from your logs, you need to customize the Logstash filters:

1. Edit or create a new Logstash pipeline file:

```
filter {
  if [type] == "your_log_type" {
    grok {
      match => { "message" => "%{YOUR_PATTERN_HERE}" }
    }
    
    # Extract security-relevant information
    if [message] =~ /error|failure|denied|rejected/ {
      mutate {
        add_tag => ["security_alert"]
        add_field => { "alert_severity" => "medium" }
      }
    }
  }
}
```

2. Restart Logstash:

```bash
docker-compose restart logstash
```

## Testing Your Configuration

1. Check if logs are being received:

```bash
docker-compose logs -f logstash
```

2. Verify logs are being properly parsed and stored in Elasticsearch:

```bash
curl -X GET "http://localhost:9200/_cat/indices?v"
```

3. Create a test security event to see if it gets flagged properly.

## Examples for Common Log Sources

### Windows Event Logs

Use Winlogbeat on Windows servers and forward to your SecuriWatch instance.

### MySQL Database Logs

Configure MySQL to log to syslog, which can then be collected by Filebeat.

### Custom Application Logs

For custom application logs, you can either:

1. Write logs to a file that Filebeat can access
2. Send logs directly to Logstash via HTTP
3. Use a specialized Beats forwarder for your application

## Troubleshooting

- Check your Filebeat and Logstash logs for errors
- Verify network connectivity between log sources and your SecuriWatch server
- Test your grok patterns using the Grok Debugger in Kibana
- Ensure you have sufficient disk space for log storage

For more assistance, check the Elastic documentation or open an issue on the SecuriWatch repository. 