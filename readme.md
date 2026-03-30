# Fetching Fathom Global Flood tiles from AWS S3
Simple scripts for fetching and indexing the global flood map layers from AWS S3.

![Fathom AWS fetch workflow](img.png)

# Setup

## install AWS CLI
To fetch the AWS tiles, ensure [AWS CLI](https://urldefense.com/v3/__https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html__;!!KwNVnqRv!AUQaTXLri175i8wdJakT49wbq0zIK8Zx2hZwpQM28FFtMrc0Vsp5YES7PmwTj0bzYR5-5pZxBBO7kKb8nAObFZU$) is installed.
On Unix, this typically looks like:

```bash
sudo apt update
sudo apt install -y awscli
```

## set up AWS credentials
Fathom will probably provide you a key and an identity.
There's a few ways to pass these to AWS. Some safe, some not-so safe.
Here, we use an `~/.aws/credentials` file with a named profile.

 
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

 

## definitive check
Now try a simple single fetch to test the connection and your credentials.
```bash
export AWS_CONFIG_FILE="$(pwd)/aws_s3.config"
export AWS_PROFILE=fathom

# show exactly which IAM identity is being used
aws sts get-caller-identity --query Arn --output text

# definitive proof command
aws s3api get-object \
  --bucket fathom-products-flood \
  --key flood-map-3/FLOOD_MAP-1ARCSEC-NW_OFFSET-1in10-COASTAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1/n00e006.tif \
  ./n00e006.tif

```
Depending on what you've been granted, you may see an error like:
`An error occurred (AccessDenied) when calling the GetObject operation: User: arn:aws:iam::288631505212:user/SethBryant is not authorized to perform: s3:GetObject on resource:`

Those permission errors occur because Fathom stores all data for full global layers in the same buckets, then provides permissions to tiles that match country boundaries.
That means attempting to sync a bucket could result in many noisy permission errors.


# Download with the fetch scripts
----------------------------------------------
Here we use a short bash script to run `aws s3 sync` on the target buckets using the profile and credentials above.

## clone the repo
```bash
git clone git@github.com:cefect/fathom_aws_fetch.git
```


## run the script
 
```bash
#change into the repo directory
cd /home/cefect/LS/09_REPOS/04_TOOLS/fathom_aws_fetch/

# make script executable
chmod +x aws_download_cmds.sh

# set output directory for fetch
export out_dir="/home/cefect/LS/10_IO/2407_FHIMP/fathom"

# run fetch script and log output
./aws_download_cmds.sh "$out_dir"

```

You should see something like `[1/36] syncing FLOOD_MAP-1ARCSEC-NW_OFFSET-1in50-PLUVIAL-DEFENDED-DEPTH-2020-PERCENTILE50-v3.1`.

## Check
Downloading will probably result in thousands of tiles.
Here are some helpers to summarize what you fetched.

### Table Of File Counts And Sizes
```bash
# totals
find "$out_dir" -type f | wc -l
du -sh --block-size=1G "$out_dir"



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

NOTE: there are no `pluvial-defended` buckets. 

# Tile Indexing

Here we use [gdaltindex](https://gdal.org/en/stable/programs/gdaltindex.html) to build a vector tile index of all the `.tif` tiles from each bucket.

## setup
If you don't have GDAL installed, a quick way (assuming you have conda) to install (and activate) is:
```bash
# create a new conda environment with gdal
conda create -n gdal_basic -c conda-forge gdal libgdal

# activate the environment
conda activate gdal_basic
 
```

## Build Tile Index For Each Bucket
These indexes are handy if you want to locate a tile for a specific location.

```bash
# make script executable
chmod +x build_grid.sh

# check your GDAL version. this script was tested against 3.12.2 "Chicoutimi"
gdalinfo --version

# run it. assumes you exported $out_dir as shown above
./build_grid.sh --target-dir "$out_dir"
 

# if you get an error like `-overwrite is not supported`, you may have an older version of GDAL. 
# either update or remove this from the script and try again.
```
this will create a set of .gpkg files (in `./tile_index`) with the same top-level names as the buckets, each containing a vector tile index of all the .tif tiles in that bucket.

# tile extract
extract a single tile from all scenarios by filename:
```bash
# change to the output directory 
cd "/home/cefect/LS/09_REPOS/04_TOOLS/floodsr_fathom/workflow_outdir/00_tiles"

# set the source directory holding the extracted scenario folders
out_dir="/home/cefect/LS/10_IO/2407_FHIMP/fathom"

# set the tile name you want to extract
tile_id="n49w124.tif"

# copy matches into the current directory, preserving top-level source folders
dest_dir="$PWD"

count=$(find "$out_dir" -type f -name "$tile_id" | wc -l)
printf "found %s matches for %s\n" "$count" "$tile_id"

find "$out_dir" -type f -name "$tile_id" | while read -r fp; do
  top_dir="$(basename "$(dirname "$fp")")"
  target_dir="$dest_dir/$top_dir"
  mkdir -p "$target_dir"
  printf "copying %s/%s\n" "$top_dir" "$tile_id"
  cp "$fp" "$target_dir/$tile_id"
done

find "$dest_dir" -mindepth 2 -maxdepth 2 -type f -name "$tile_id" | wc -l

```




# archive

## create archives
```bash
out_dir=/home/cefect/LS/10_IO/2407_FHIMP/fathom
archive_dir=/home/cefect/LS/10_IO/2407_FHIMP/fathom_arch

# clear out empty folders
find "$out_dir" -type d -empty -delete

# tarball each top-level directory with native tar progress dots and medium zstd compression
# TODO: refactor into standalone and extend for Use tmp output + zstd -tq validation + source-vs-archive mtime check.
cd "$out_dir"
echo "archiving each top-level directory in $out_dir to $archive_dir"
for dir in */; do
    [ -d "$dir" ] || continue
    echo "archiving $dir -> $archive_dir/${dir%/}.tar.zst"
    tar --checkpoint=1000 --checkpoint-action=dot -I 'zstd -5 -T0' \
      -cf "$archive_dir/${dir%/}.tar.zst" "$dir"
done
```
## unpack
```bash
# extract each `.tar.zst` archive from `fathom_arch` into the shared output root
 
mkdir -p /home/cefect/LS/10_IO/2407_FHIMP/fathom && \
count=$(find /home/cefect/LS/10_IO/2407_FHIMP/fathom_arch -maxdepth 1 -type f -name '*.tar.zst' | wc -l) && \
i=0 && \
for fp in /home/cefect/LS/10_IO/2407_FHIMP/fathom_arch/*.tar.zst; do
  i=$((i + 1))
  printf '[%s/%s] extracting %s\n' "$i" "$count" "$(basename "$fp")"
  tar --zstd -xf "$fp" -C /home/cefect/LS/10_IO/2407_FHIMP/fathom
done

 

```


# See Also
[titiler](https://github.com/developmentseed/titiler)
