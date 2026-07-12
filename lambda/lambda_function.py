import boto3

s3 = boto3.client("s3")

# move objects under reports/ in one bucket to reports/scanned/ in a second bucket 
SOURCE_BUCKET = "african-mentorship-bucket-nic"
DESTINATION_BUCKET = "african-mentorship-bucket-nic-scanned"

SOURCE_PREFIX = "reports/"
DESTINATION_PREFIX = "reports/scanned/"


def lambda_handler(event, context):
    moved_files = []
    skipped_files = []

    #Paginate through the source prefix
    paginator = s3.get_paginator("list_objects_v2")

    for page in paginator.paginate(
        Bucket=SOURCE_BUCKET,
        Prefix=SOURCE_PREFIX
    ):
        objects = page.get("Contents", [])

        for obj in objects:
            source_key = obj["Key"]

            # Skip folder placeholders
            if source_key.endswith("/"):
                skipped_files.append(source_key)
                continue

            filename = source_key.replace(SOURCE_PREFIX, "", 1)

            # Skip files already marked as scanned
            if "_scanned" in filename:
                skipped_files.append(source_key)
                continue

            scanned_filename = add_scanned_to_filename(filename)
            destination_key = DESTINATION_PREFIX + scanned_filename

            # Copy file to destination bucket
            s3.copy_object(
                Bucket=DESTINATION_BUCKET,
                CopySource={
                    "Bucket": SOURCE_BUCKET,
                    "Key": source_key
                },
                Key=destination_key
            )

            # Delete original file from source bucket
            s3.delete_object(
                Bucket=SOURCE_BUCKET,
                Key=source_key
            )

            moved_files.append({
                "source": f"s3://{SOURCE_BUCKET}/{source_key}",
                "destination": f"s3://{DESTINATION_BUCKET}/{destination_key}"
            })

    return {
        "statusCode": 200,
        "message": "Files moved to scanned bucket successfully",
        "moved_count": len(moved_files),
        "skipped_count": len(skipped_files),
        "moved_files": moved_files,
        "skipped_files": skipped_files
    }


def add_scanned_to_filename(filename):
    """
    Adds _scanned before the file extension.

    Example:
    report.csv -> report_scanned.csv
    report.pdf -> report_scanned.pdf
    report -> report_scanned
    """

    if "." in filename:
        name, extension = filename.rsplit(".", 1)
        return f"{name}_scanned.{extension}"

    return f"{filename}_scanned"