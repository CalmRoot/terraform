const { DynamoDBClient, ScanCommand } = require("@aws-sdk/client-dynamodb");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION || "us-east-1" });
const s3Client = new S3Client({ region: process.env.AWS_REGION || "us-east-1" });

exports.handler = async (event) => {
  console.log("Starting daily export job...", JSON.stringify(event));

  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const dateStr = now.toISOString().split('T')[0];

  try {
    // 1. Scan Assessments (calmroot-assessments)
    console.log("Scanning DynamoDB calmroot-assessments table...");
    const assessmentsScan = await ddbClient.send(new ScanCommand({
      TableName: "calmroot-assessments"
    }));

    // Filter assessments from the last 24 hours
    const recentAssessments = (assessmentsScan.Items || []).map(item => unmarshallItem(item))
      .filter(item => {
        const itemDate = new Date(item.createdAt || item.timestamp || now);
        return itemDate >= oneDayAgo;
      });

    // 2. Scan Mood Logs (calmroot-mood-logs)
    console.log("Scanning DynamoDB calmroot-mood-logs table...");
    const moodLogsScan = await ddbClient.send(new ScanCommand({
      TableName: "calmroot-mood-logs"
    }));

    // Filter mood logs from the last 24 hours
    const recentMoodLogs = (moodLogsScan.Items || []).map(item => unmarshallItem(item))
      .filter(item => {
        const itemDate = new Date(item.createdAt || item.timestamp || now);
        return itemDate >= oneDayAgo;
      });

    // 3. Upload Assessments to S3
    const assessmentKey = `assessments/${dateStr}.json`;
    console.log(`Uploading assessments to S3: s3://calmroot-daily-exports/${assessmentKey}`);
    await s3Client.send(new PutObjectCommand({
      Bucket: "calmroot-daily-exports",
      Key: assessmentKey,
      Body: JSON.stringify(recentAssessments, null, 2),
      ContentType: "application/json"
    }));

    // 4. Upload Mood Logs to S3
    const moodKey = `mood-logs/${dateStr}.json`;
    console.log(`Uploading mood logs to S3: s3://calmroot-daily-exports/${moodKey}`);
    await s3Client.send(new PutObjectCommand({
      Bucket: "calmroot-daily-exports",
      Key: moodKey,
      Body: JSON.stringify(recentMoodLogs, null, 2),
      ContentType: "application/json"
    }));

    console.log("Daily export job completed successfully!");
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Export completed", date: dateStr })
    };
  } catch (error) {
    console.error("Error running daily export:", error);
    throw error;
  }
};

// Simplified unmarshal helper for DynamoDB AttributeValues
function unmarshallItem(item) {
  const result = {};
  for (const key in item) {
    const val = item[key];
    if (val.S !== undefined) result[key] = val.S;
    else if (val.N !== undefined) result[key] = Number(val.N);
    else if (val.BOOL !== undefined) result[key] = val.BOOL;
    else if (val.M !== undefined) result[key] = unmarshallItem(val.M);
    else if (val.L !== undefined) result[key] = val.L.map(i => i.S || i.N || i.BOOL || i);
    else result[key] = val;
  }
  return result;
}
