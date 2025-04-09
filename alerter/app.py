#!/usr/bin/env python3
"""
SecuriWatch Alert Service

A simple service to send notifications for security alerts.
Supports email and webhook notifications.
"""

import os
import json
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import requests
from flask import Flask, request, jsonify
from datetime import datetime
import yaml
from dotenv import load_dotenv
from jinja2 import Template

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("alerter")

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Load config
CONFIG_FILE = os.environ.get("CONFIG_FILE", "/app/config/config.yml")

# Default config values
DEFAULT_CONFIG = {
    "email": {
        "enabled": False,
        "smtp_server": os.environ.get("SMTP_SERVER", ""),
        "smtp_port": int(os.environ.get("SMTP_PORT", 587)),
        "smtp_user": os.environ.get("SMTP_USER", ""),
        "smtp_password": os.environ.get("SMTP_PASSWORD", ""),
        "from_address": os.environ.get("ALERT_FROM", "alerter@securiwatch.local"),
        "to_addresses": [addr.strip() for addr in os.environ.get("ALERT_TO", "").split(",") if addr.strip()],
        "subject_template": "SecuriWatch Alert: {{ severity | upper }} - {{ event_type }}",
        "body_template": """
        <h2>SecuriWatch Security Alert</h2>
        <p><strong>Severity:</strong> {{ severity | upper }}</p>
        <p><strong>Source:</strong> {{ source }}</p>
        <p><strong>Timestamp:</strong> {{ timestamp }}</p>
        <p><strong>Event Type:</strong> {{ event_type }}</p>
        <p><strong>Message:</strong></p>
        <pre>{{ message }}</pre>
        """
    },
    "webhook": {
        "enabled": False,
        "urls": [url.strip() for url in os.environ.get("WEBHOOK_URLS", "").split(",") if url.strip()],
        "method": "POST",
        "headers": {
            "Content-Type": "application/json"
        }
    },
    "alert_rate_limit": {
        "enabled": True,
        "window_seconds": 300,  # 5 minutes
        "max_similar_alerts": 3
    }
}

# Store for rate limiting
alert_history = {}

def load_config():
    """Load configuration from file or use defaults"""
    config = DEFAULT_CONFIG.copy()
    
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r') as f:
                file_config = yaml.safe_load(f)
                
            # Merge configs
            if file_config:
                if "email" in file_config:
                    config["email"].update(file_config["email"])
                if "webhook" in file_config:
                    config["webhook"].update(file_config["webhook"])
                if "alert_rate_limit" in file_config:
                    config["alert_rate_limit"].update(file_config["alert_rate_limit"])
                    
            logger.info(f"Loaded configuration from {CONFIG_FILE}")
        except Exception as e:
            logger.error(f"Error loading config file: {e}")
    else:
        logger.warning(f"Config file {CONFIG_FILE} not found, using default configuration")

    # Set enabled flags based on environment
    if os.environ.get("SMTP_SERVER"):
        config["email"]["enabled"] = True
    if os.environ.get("WEBHOOK_URLS"):
        config["webhook"]["enabled"] = True
        
    return config

config = load_config()

def send_email_alert(alert_data):
    """Send an email alert"""
    if not config["email"]["enabled"]:
        logger.info("Email alerts disabled, skipping")
        return False
    
    if not config["email"]["to_addresses"]:
        logger.warning("No recipient email addresses configured")
        return False
    
    try:
        # Render templates
        subject_template = Template(config["email"]["subject_template"])
        body_template = Template(config["email"]["body_template"])
        
        subject = subject_template.render(**alert_data)
        body = body_template.render(**alert_data)
        
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = config["email"]["from_address"]
        msg['To'] = ", ".join(config["email"]["to_addresses"])
        
        # Create HTML part
        part = MIMEText(body, 'html')
        msg.attach(part)
        
        # Connect to server and send
        server = smtplib.SMTP(config["email"]["smtp_server"], config["email"]["smtp_port"])
        server.starttls()
        
        if config["email"]["smtp_user"] and config["email"]["smtp_password"]:
            server.login(config["email"]["smtp_user"], config["email"]["smtp_password"])
        
        server.sendmail(
            config["email"]["from_address"], 
            config["email"]["to_addresses"], 
            msg.as_string()
        )
        server.quit()
        
        logger.info(f"Email alert sent to {', '.join(config['email']['to_addresses'])}")
        return True
    except Exception as e:
        logger.error(f"Failed to send email alert: {e}")
        return False

def send_webhook_alert(alert_data):
    """Send an alert to configured webhooks"""
    if not config["webhook"]["enabled"]:
        logger.info("Webhook alerts disabled, skipping")
        return False
    
    if not config["webhook"]["urls"]:
        logger.warning("No webhook URLs configured")
        return False
    
    success = False
    
    for url in config["webhook"]["urls"]:
        try:
            response = requests.request(
                method=config["webhook"]["method"],
                url=url,
                headers=config["webhook"]["headers"],
                json=alert_data,
                timeout=5
            )
            
            if response.status_code < 400:
                logger.info(f"Webhook alert sent to {url} (Status: {response.status_code})")
                success = True
            else:
                logger.warning(f"Webhook returned error status: {response.status_code} for {url}")
        except Exception as e:
            logger.error(f"Failed to send webhook alert to {url}: {e}")
    
    return success

def should_rate_limit(alert_data):
    """Check if an alert should be rate limited"""
    if not config["alert_rate_limit"]["enabled"]:
        return False
    
    # Create a simple key for the alert based on type and source
    alert_key = f"{alert_data.get('event_type', '')}-{alert_data.get('source', '')}-{alert_data.get('severity', '')}"
    
    current_time = datetime.now().timestamp()
    window_seconds = config["alert_rate_limit"]["window_seconds"]
    max_similar = config["alert_rate_limit"]["max_similar_alerts"]
    
    # Clean old entries
    for key in list(alert_history.keys()):
        alert_history[key] = [t for t in alert_history[key] if current_time - t < window_seconds]
        if not alert_history[key]:
            del alert_history[key]
    
    # Check and update current alert
    if alert_key not in alert_history:
        alert_history[alert_key] = [current_time]
        return False
    
    if len(alert_history[alert_key]) < max_similar:
        alert_history[alert_key].append(current_time)
        return False
    
    logger.info(f"Rate limiting alert: {alert_key} (exceeded {max_similar} alerts in {window_seconds}s)")
    return True

@app.route('/alert', methods=['POST'])
def receive_alert():
    """Receive alert from Logstash or other sources"""
    try:
        alert_data = request.json
        
        if not alert_data:
            return jsonify({"status": "error", "message": "No data provided"}), 400
        
        # Ensure required fields
        required_fields = ["severity", "message"]
        for field in required_fields:
            if field not in alert_data:
                return jsonify({
                    "status": "error", 
                    "message": f"Missing required field: {field}"
                }), 400
        
        # Add timestamp if not present
        if "timestamp" not in alert_data:
            alert_data["timestamp"] = datetime.now().isoformat()
            
        # Set defaults for optional fields
        if "source" not in alert_data:
            alert_data["source"] = "unknown"
        if "event_type" not in alert_data:
            alert_data["event_type"] = "security_alert"
            
        # Check rate limiting
        if should_rate_limit(alert_data):
            return jsonify({
                "status": "rate_limited", 
                "message": "Alert rate limited"
            }), 429
            
        # Log the alert
        logger.info(f"Received {alert_data['severity']} alert from {alert_data['source']}")
        
        # Send notifications
        email_sent = send_email_alert(alert_data)
        webhook_sent = send_webhook_alert(alert_data)
        
        if email_sent or webhook_sent:
            return jsonify({
                "status": "success", 
                "message": "Alert processed"
            }), 200
        else:
            return jsonify({
                "status": "warning", 
                "message": "Alert received but no notifications were sent"
            }), 202
            
    except Exception as e:
        logger.error(f"Error processing alert: {e}")
        return jsonify({
            "status": "error", 
            "message": f"Server error: {str(e)}"
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "config": {
            "email_enabled": config["email"]["enabled"],
            "webhook_enabled": config["webhook"]["enabled"],
            "rate_limiting_enabled": config["alert_rate_limit"]["enabled"]
        }
    })

@app.route('/', methods=['GET'])
def index():
    """Root endpoint with basic info"""
    return jsonify({
        "service": "SecuriWatch Alerter",
        "version": "1.0.0",
        "endpoints": {
            "/alert": "POST - Send an alert",
            "/health": "GET - Health check"
        }
    })

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port) 