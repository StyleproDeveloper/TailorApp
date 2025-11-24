const { STSClient, GetCallerIdentityCommand } = require('@aws-sdk/client-sts');
require('dotenv').config({ path: './backend/.env' });

async function getAWSAccountId() {
  try {
    // Check if AWS credentials are configured
    if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
      console.log('❌ AWS credentials not configured');
      console.log('   Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in your .env file');
      return;
    }

    console.log('🔍 Retrieving AWS Account Information...\n');

    // Create STS client
    const stsClient = new STSClient({
      region: process.env.AWS_REGION || 'ap-south-1',
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      },
    });

    // Get caller identity (which includes account ID)
    const command = new GetCallerIdentityCommand({});
    const response = await stsClient.send(command);

    console.log('✅ AWS Account Information:');
    console.log(`   Account ID: ${response.Account}`);
    console.log(`   User ARN: ${response.Arn}`);
    console.log(`   User ID: ${response.UserId}`);
    console.log(`   Region: ${process.env.AWS_REGION || 'ap-south-1'}`);
    console.log(`   Access Key ID: ${process.env.AWS_ACCESS_KEY_ID.substring(0, 8)}...`);

    console.log('\n📦 S3 Buckets:');
    console.log(`   All S3 buckets created by this application will be in AWS Account: ${response.Account}`);
    console.log(`   Bucket naming format: tailorapp-{shopName}-{shopId}`);

  } catch (error) {
    console.error('❌ Error retrieving AWS account information:', error.message);
    if (error.name === 'InvalidClientTokenId' || error.name === 'SignatureDoesNotMatch') {
      console.error('   This usually means the AWS credentials are invalid or incorrect.');
    } else if (error.name === 'NetworkingError' || error.code === 'ENOTFOUND') {
      console.error('   Network error - please check your internet connection.');
    } else {
      console.error('   Full error:', error);
    }
  }
}

getAWSAccountId();

