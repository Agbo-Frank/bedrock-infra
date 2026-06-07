exports.handler = async (event) => {
  for (const record of event.Records) {
    const bucket = record.s3.bucket.name;
    const filename = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));

    console.log(`Image received: ${filename}`);
    console.log(`Bucket: ${bucket}`);
  }

  return {
    statusCode: 200,
    body: "Processed successfully",
  };
};
