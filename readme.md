# Fetching fathom products from AWS S3


# setup (one time)

## install AWS CLI
to fetch the aws tiles, ensure [AWS CLI](https://urldefense.com/v3/__https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html__;!!KwNVnqRv!AUQaTXLri175i8wdJakT49wbq0zIK8Zx2hZwpQM28FFtMrc0Vsp5YES7PmwTj0bzYR5-5pZxBBO7kKb8nAObFZU$) is installed. 
On unix, this typically looks like:

```bash
sudo apt update
sudo apt install -y awscli
```

## set up AWS credentials 
probably fathom will provide you a key and an identity. 
There's a few ways to pass these to AWS. Some safe, some not-so safe.
Here we use an `~/.aws/credentials` file with a named profile.

 
Create `~/.aws/credentials` with a named profile:

```ini
[fathom]
aws_access_key_id = <your_id>
aws_secret_access_key = <your_key>
```

The fetch script sets `AWS_CONFIG_FILE` to this repo's [`aws_s3.config`](aws_s3.config) and defaults `AWS_PROFILE` to `fathom`, so it ignores the user's `~/.aws/config`.

Lock down the credentials file and test against the repo config:

```bash
chmod 600 ~/.aws/credentials
export AWS_CONFIG_FILE="$(pwd)/aws_s3.config"
export AWS_PROFILE=fathom
aws sts get-caller-identity --query Arn --output text
```

 

## definitive no-access check (WSL)
now try a simple single fetch to test the connection and your credentials. 
```bash
export AWS_CONFIG_FILE="$(pwd)/aws_s3.config"
export AWS_PROFILE=fathom

# show exactly which IAM identity is being used
aws sts get-caller-identity --query Arn --output text

# definitive proof command
aws s3api get-object \
  --bucket fathom-products-flood \
  --key flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in10-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1/n00e006.tif \
  /n00e006.tif

```
Depending on what you've been granted, you may see an error like:
`An error occurred (AccessDenied) when calling the GetObject operation: User: arn:aws:iam::288631505212:user/SethBryant is not authorized to perform: s3:GetObject on resource:`

Those permission errors occur because fathom stores all data for full global layers in the same buckets, then provide permissions to tiles that match country boundaries.
Which means, attempting to sync a bucket could result in many noisy permission errors.


# run the download
----------------------------------------------------------
Here we use a short bash script to run `aws s3 sync` on the target buckets using the above profile + credentials.
 
```bash
# make script executable
chmod +x aws_download_cmds.sh

# set output directory for fetch
export out_dir=download

# run fetch script and log output
./aws_download_cmds.sh "$out_dir"

```

you should see something like `[1/36] syncing FLOOD_MAP-1ARCSEC-NW_OFFSET-1in50-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1`. 

## check
downloading probably results in thousands of tiles.
Here are some nice helpers to summarize what you fetched. 

### table of file counts and sizes
```bash
# assumes you exported $out_dir as shown above
{
  printf $'filename\tfilesize_gb\tfile_count\n'
  find "$out_dir" -mindepth 1 -maxdepth 1 -type d -print0 |
    while IFS= read -r -d '' d; do
      printf "%s\t%.3f\t%s\n" \
        "$(basename "$d")" \
        "$(du -s -B1 "$d" | awk '{print $1/1024/1024/1024}')" \
        "$(find "$d" -type f | wc -l)"
    done | sort -t$'\t' -k2,2nr
} > fetch_size.tsv
```

### build tile index for each bucket
here we use [gdaltindex](https://gdal.org/en/stable/programs/gdaltindex.html) to build a vector tile index of all the .tif tiles from each bucket.
If you dont have gdal installed, a quick way (assuming you have conda) is:
```bash
# create a new conda environment with gdal
`conda create -n gdal_basic -c conda-forge gdal libgdal`
 
```


These indexes are handy if you want to locate a tile for a specific location. 

```bash
# make script executable
chmod +x build_grid.sh

# check your gdal version. this script was tested against 3.12.2 "Chicoutimi"
gdalinfo --version

# run it. assumes you exported $out_dir as shown above
./build_grid.sh --target-dir "$out_dir"

# if you get an error like `-overwrite is not supported`, you may have an older version of gdal. either update or remove this from teh script and try again.
```
