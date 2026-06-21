const { S3Client, ListBucketsCommand, HeadBucketCommand, ListObjectsV2Command } = require("@aws-sdk/client-s3");

const s3 = new S3Client({ region: "us-east-1" });

async function run() {
  console.log("Checking AWS S3 connection...");
  try {
    const buckets = await s3.send(new ListBucketsCommand({}));
    console.log("Successfully connected! Found buckets:");
    for (const b of buckets.Buckets || []) {
      console.log(` - ${b.Name}`);
    }

    const bucketName = "calmroot-terraform-state";
    console.log(`Checking bucket: ${bucketName}...`);
    try {
      await s3.send(new HeadBucketCommand({ Bucket: bucketName }));
      console.log(`Bucket ${bucketName} exists and is accessible.`);

      // List objects
      const objects = await s3.send(new ListObjectsV2Command({ Bucket: bucketName }));
      console.log(`Objects in ${bucketName}:`);
      for (const obj of objects.Contents || []) {
        console.log(` - ${obj.Key} (Size: ${obj.Size} bytes)`);
      }
    } catch (err) {
      console.error(`Error accessing bucket ${bucketName}:`, err.message);
    }

  } catch (err) {
    console.error("AWS S3 connection failed:", err.message);
  }
}

run();
