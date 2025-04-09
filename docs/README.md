# SecuriWatch Documentation

Welcome to the SecuriWatch documentation. This directory contains guides and references to help you get the most out of your security monitoring system.

## Available Documents

- [Quickstart Guide](quickstart.md) - Get started in minutes with minimal configuration
- [Server Deployment Guide](server-deployment.md) - Instructions for deploying SecuriWatch on a production server
- [Adding Log Sources](adding-log-sources.md) - How to add and configure additional log sources

## Additional Resources

### Elasticsearch & Kibana

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Elasticsearch Security Features](https://www.elastic.co/guide/en/elasticsearch/reference/current/secure-cluster.html)

### Wazuh

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Wazuh Rules Reference](https://documentation.wazuh.com/current/user-manual/ruleset/rules-classification.html)

### Logstash & Filebeat

- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Filebeat Documentation](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [Grok Pattern Reference](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html)

## Quick References

### Common Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs for a specific service
docker-compose logs -f [service_name]

# Check service status
docker-compose ps

# Run health check
./scripts/healthcheck.sh

# Update configuration and restart services
docker-compose restart [service_name]
```

### Security Alerts

SecuriWatch classifies security alerts into the following severity levels:

- **Critical** - Immediate action required, potential breach in progress
- **High** - Serious security threat requiring prompt action
- **Medium** - Potential security issue that should be investigated
- **Low** - Minor security concern or informational alert

## Getting Help

If you encounter issues with SecuriWatch, please:

1. Check the troubleshooting section in each guide
2. Review the service logs for error messages
3. Consult the documentation for the underlying components
4. Contact your system administrator or create an issue on the SecuriWatch repository 