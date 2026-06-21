const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const region = process.env.AWS_REGION || 'us-east-1';
const ddbClient = new DynamoDBClient({ region });
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);
const s3Client = new S3Client({ region });

const EXPORTS_BUCKET = process.env.EXPORTS_BUCKET || 'calmroot-daily-exports';

exports.handler = async (event) => {
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);
  
  const yesterdayStr = yesterday.toISOString();
  const dateStr = today.toISOString().split('T')[0];

  console.log(`Starting daily export for date: ${dateStr}. Fetching records since ${yesterdayStr}...`);

  try {
    // 1. Export Assessments
    console.log('Scanning assessments...');
    const assessmentsScan = await ddbDocClient.send(new ScanCommand({
      TableName: 'calmroot-assessments'
    }));
    
    const allAssessments = assessmentsScan.Items || [];
    const recentAssessments = allAssessments.filter(item => {
      // Must be an assessment result
      if (!item.SK || !item.SK.startsWith('ASSESSMENT#')) return false;
      const takenAt = item.takenAt || item.createdAt;
      return takenAt && takenAt >= yesterdayStr;
    });

    console.log(`Found ${recentAssessments.length} assessments to export.`);
    const assessmentsKey = `daily-exports/assessments/${dateStr}.json`;
    await s3Client.send(new PutObjectCommand({
      Bucket: EXPORTS_BUCKET,
      Key: assessmentsKey,
      Body: JSON.stringify(recentAssessments, null, 2),
      ContentType: 'application/json'
    }));
    console.log(`Uploaded assessments to s3://${EXPORTS_BUCKET}/${assessmentsKey}`);

    // 2. Export Mood Logs
    console.log('Scanning mood logs...');
    const moodScan = await ddbDocClient.send(new ScanCommand({
      TableName: 'calmroot-mood-logs'
    }));

    const allMoodLogs = moodScan.Items || [];
    const recentMoodLogs = allMoodLogs.filter(item => {
      if (!item.SK || !item.SK.startsWith('MOOD#')) return false;
      const createdAt = item.createdAt || item.loggedAt;
      return createdAt && createdAt >= yesterdayStr;
    });

    console.log(`Found ${recentMoodLogs.length} mood logs to export.`);
    const moodLogsKey = `daily-exports/mood-logs/${dateStr}.json`;
    await s3Client.send(new PutObjectCommand({
      Bucket: EXPORTS_BUCKET,
      Key: moodLogsKey,
      Body: JSON.stringify(recentMoodLogs, null, 2),
      ContentType: 'application/json'
    }));
    console.log(`Uploaded mood logs to s3://${EXPORTS_BUCKET}/${moodLogsKey}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Daily export completed successfully',
        assessmentsCount: recentAssessments.length,
        moodLogsCount: recentMoodLogs.length,
        date: dateStr
      })
    };
  } catch (error) {
    console.error('Error during daily export:', error);
    throw error;
  }
};
