import boto3
import csv
import json
from io import StringIO

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Get the bucket and object key from the Event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    file_key = event['Records'][0]['s3']['object']['key']

    # Check if the file is a CSV based on the file extension
    if not file_key.lower().endswith('.csv'):
        return {
            'statusCode': 200,
            'body': json.dumps('File is not a CSV, no action taken')
        }

    try:
        # Get the CSV file from S3
        csv_file = s3.get_object(Bucket=bucket_name, Key=file_key)
        csv_content = csv_file['Body'].read().decode('utf-8')

        # Convert CSV to JSON
        csv_reader = csv.DictReader(StringIO(csv_content))
        json_data = [row for row in csv_reader]

        # Construct the file name for the JSON output
        json_file_key = file_key.rsplit('.', 1)[0] + '.json'
        
        # Write JSON to a new file in S3
        s3.put_object(Bucket=bucket_name, Key=json_file_key, Body=json.dumps(json_data))

        return {
            'statusCode': 200,
            'body': json.dumps('CSV to JSON conversion successful')
        }

    except Exception as e:
        print(e)
        raise e