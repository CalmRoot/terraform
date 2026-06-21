import os
import json
import boto3
import traceback
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime

# =====================================================
# AWS CLIENTS
# =====================================================
region = os.environ.get('AWS_REGION', 'us-east-1')
ses = boto3.client('ses', region_name=region)

# =====================================================
# EMAIL CONFIGURATION
# =====================================================
ops_email = os.environ.get('OPS_EMAIL', 'bharath70135@gmail.com')
SENDER = ops_email
RECIPIENT = ops_email
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'production')

# =====================================================
# MAIN LAMBDA FUNCTION
# =====================================================
def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    for record in event.get('Records', []):
        try:
            # SNS Message
            raw_message = record.get('Sns', {}).get('Message', '')

            # Parse JSON
            try:
                msg = json.loads(raw_message)
            except Exception:
                msg = {"Message": raw_message}

            # Initialize defaults
            color = "#2563eb"  # Blue
            emoji = "⚙️"
            title = "SYSTEM ALERT"
            status = "INFO"
            alarm_name = "Unknown Event"
            description = "No description provided"
            formatted_time = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')

            # =====================================================
            # CLOUDWATCH ALARM EVENTS
            # =====================================================
            if 'AlarmName' in msg:
                alarm_name = str(msg.get('AlarmName', 'Unknown Alarm') or 'Unknown Alarm')
                new_state = str(msg.get('NewStateValue', 'UNKNOWN') or 'UNKNOWN')
                reason = str(msg.get('NewStateReason', 'No reason provided') or 'No reason provided')
                time_str = str(msg.get('StateChangeTime', '') or '')

                if time_str:
                    try:
                        # Parse StateChangeTime e.g., 2026-06-09T06:38:10.000Z
                        dt = datetime.strptime(time_str.split('.')[0].replace('Z', ''), '%Y-%m-%dT%H:%M:%S')
                        formatted_time = dt.strftime('%Y-%m-%d %H:%M:%S UTC')
                    except Exception:
                        formatted_time = time_str

                if new_state == "ALARM":
                    color = "#dc2626"  # Red
                    emoji = "🚨"
                    title = "CLOUDWATCH ALARM TRIGGERED"
                    status = "ALARM STATE"
                elif new_state == "OK":
                    color = "#16a34a"  # Green
                    emoji = "✅"
                    title = "CLOUDWATCH ALARM RECOVERED"
                    status = "RECOVERY STATE"
                else:
                    color = "#2563eb"  # Blue
                    emoji = "⚙️"
                    title = f"CLOUDWATCH STATE: {new_state}"
                    status = new_state

                description = reason
                subject = f"{emoji} {alarm_name} - {new_state}"

            # =====================================================
            # AUTO SCALING EVENTS
            # =====================================================
            elif 'AutoScalingGroupName' in msg or 'Event' in msg:
                event_type = str(msg.get('Event', 'Unknown Event') or 'Unknown Event')
                asg = str(msg.get('AutoScalingGroupName', 'Unknown ASG') or 'Unknown ASG')
                instance = str(msg.get('EC2InstanceId', 'N/A') or 'N/A')
                cause = str(msg.get('Cause', 'No cause provided') or 'No cause provided')
                time_str = str(msg.get('Time', '') or '')

                if time_str:
                    try:
                        dt = datetime.strptime(time_str.split('.')[0].replace('Z', ''), '%Y-%m-%dT%H:%M:%S')
                        formatted_time = dt.strftime('%Y-%m-%d %H:%M:%S UTC')
                    except Exception:
                        formatted_time = time_str

                if "launch" in event_type.lower():
                    color = "#16a34a"  # Green
                    emoji = "🚀"
                    title = "INSTANCE LAUNCHED"
                    status = "SCALE OUT EVENT"
                elif "terminate" in event_type.lower():
                    color = "#dc2626"  # Red
                    emoji = "🛑"
                    title = "INSTANCE TERMINATED"
                    status = "SCALE IN EVENT"
                else:
                    color = "#2563eb"  # Blue
                    emoji = "⚙️"
                    title = "AUTO SCALING EVENT"
                    status = "ASG EVENT"

                alarm_name = f"{event_type} | {asg}"
                description = f"Instance ID: {instance}\nASG: {asg}\nCause: {cause}"
                subject = f"{emoji} {title} | {asg}"

            # =====================================================
            # OTHER EVENT PAYLOADS
            # =====================================================
            else:
                alarm_name = "System Alert"
                description = str(msg.get('Message', raw_message) or raw_message)
                subject = f"⚙️ CalmRoot System Event"

            # =====================================================
            # BEAUTIFUL HTML EMAIL TEMPLATE
            # =====================================================
            html_body = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    @keyframes pulse {{
      0% {{ box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }}
      70% {{ box-shadow: 0 0 0 10px rgba(239, 68, 68, 0); }}
      100% {{ box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }}
    }}
  </style>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background: #0b0f19; color: #f3f4f6; margin: 0; padding: 40px 20px;">
  <div style="max-width: 600px; margin: auto; background: #111827; border: 1px solid #1f2937; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3), 0 8px 10px -6px rgba(0, 0, 0, 0.3);">
    
    <!-- Top banner with state color -->
    <div style="background: linear-gradient(135deg, {color} 0%, #111827 80%); padding: 32px; text-align: left; border-bottom: 1px solid #1f2937;">
      <span style="color: {color}; font-weight: 700; text-transform: uppercase; font-size: 14px; letter-spacing: 0.1em; vertical-align: middle;">System Alert</span>
      <h1 style="color: white; margin: 12px 0 0 0; font-size: 26px; font-weight: 800; letter-spacing: -0.02em;">CalmRoot Operations</h1>
    </div>

    <div style="padding: 32px;">
      <h2 style="color: white; font-size: 18px; font-weight: 700; margin-top: 0; margin-bottom: 24px; line-height: 1.4;">{alarm_name}</h2>
      
      <!-- Key Metric Panel -->
      <div style="background: #1f2937; border-radius: 12px; padding: 24px; margin-bottom: 28px; border: 1px solid #374151;">
        <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; color: #9ca3af; font-weight: 600;">Status State</div>
        <div style="font-size: 24px; font-weight: 800; color: {color}; margin-top: 4px;">
          {emoji} {status}
        </div>
      </div>

      <!-- Detail list -->
      <table style="width: 100%; border-collapse: collapse; margin-bottom: 28px;">
        <tr>
          <td style="padding: 12px 0; border-bottom: 1px solid #1f2937; color: #9ca3af; font-size: 14px; width: 120px; font-weight: 500; vertical-align: top;">Description</td>
          <td style="padding: 12px 0; border-bottom: 1px solid #1f2937; color: #e5e7eb; font-size: 14px; line-height: 1.5; white-space: pre-line;">{description}</td>
        </tr>
        <tr>
          <td style="padding: 12px 0; border-bottom: 1px solid #1f2937; color: #9ca3af; font-size: 14px; font-weight: 500; vertical-align: top;">Triggered Time</td>
          <td style="padding: 12px 0; border-bottom: 1px solid #1f2937; color: #e5e7eb; font-size: 14px; vertical-align: top;">{formatted_time}</td>
        </tr>
        <tr>
          <td style="padding: 12px 0; border-bottom: 1px solid #1f2937; color: #9ca3af; font-size: 14px; font-weight: 500; vertical-align: top;">Cloud Region</td>
          <td style="padding: 12px 0; border-bottom: 1px solid #1f2937; color: #e5e7eb; font-size: 14px; font-family: monospace; vertical-align: top;">{region}</td>
        </tr>
        <tr>
          <td style="padding: 12px 0; color: #9ca3af; font-size: 14px; font-weight: 500; vertical-align: top;">Environment</td>
          <td style="padding: 12px 0; color: #e5e7eb; font-size: 14px; text-transform: capitalize; vertical-align: top;">{ENVIRONMENT}</td>
        </tr>
      </table>

      <!-- Call to Action Buttons -->
      <div style="text-align: center; margin-top: 10px;">
        <a href="https://console.aws.amazon.com/cloudwatch/home?region={region}#alarmsV2:" style="background: #3b82f6; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 14px; display: inline-block; box-shadow: 0 4px 14px 0 rgba(59, 130, 246, 0.4);">Open CloudWatch</a>
      </div>
    </div>

    <!-- Footer -->
    <div style="background: #0f172a; padding: 20px; text-align: center; font-size: 12px; color: #64748b; border-top: 1px solid #1f2937;">
      CalmRoot Platform Monitoring • Powered by AWS SES & Lambda
      <br>
      <a href="https://calmroot-project.online" style="color: #3b82f6; text-decoration: none; margin-top: 8px; display: inline-block;">calmroot-project.online</a>
    </div>
  </div>
</body>
</html>"""

            # =====================================================
            # MIME EMAIL CREATION
            # =====================================================
            email_msg = MIMEMultipart('alternative')
            email_msg['Subject'] = subject
            email_msg['From'] = SENDER
            email_msg['To'] = RECIPIENT

            html_part = MIMEText(html_body, 'html')
            email_msg.attach(html_part)

            # =====================================================
            # SEND EMAIL USING SES (Sending as raw bytes)
            # =====================================================
            response = ses.send_raw_email(
                Source=SENDER,
                Destinations=[RECIPIENT],
                RawMessage={
                    'Data': email_msg.as_bytes()
                }
            )
            print("SES send raw email response:", response)
        except Exception as err:
            print("Failed to process record.")
            traceback.print_exc()

    return {
        'statusCode': 200,
        'body': 'Beautiful HTML Notification Sent Successfully'
    }
