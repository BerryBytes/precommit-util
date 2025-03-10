
# Known Issues

This document outlines acknowledged issues with GitHub Desktop, including workarounds if known.

## What should I do if...

### I have encountered an issue listed here?

Some known issues have a workaround that users have reported addresses the issue. Please try the workaround for yourself to confirm it addresses the issue.

### I have additional questions about an issue listed here?

Each known issue links off to an existing GitHub issue. If you have additional questions or feedback, please comment on the issue.

### My issue is not listed here?

Please check the [open](https://github.com/01cloud/01cloud-githooks/issues) and [closed](https://github.com/01cloud/01cloud-githooks/issues?q=is%3Aissue+is%3Aclosed) bugs in the issue tracker for the details of your bug. If you can't find it, or if you're not sure, open a [new issue](https://github.com/01cloud/01cloud-githooks/issues/new).

## 

### Python dependencies not installed
If you are getting an error like python dependencies not installed, please run the following command in your terminal

**Workaround:**

```
sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python3-openssl 
```
##

### Error while installing Terraform
Terraform requires to unzip the terraform binary file. If you are getting an while installing terraform error that doesn't have any unzip command, please run the following command in your terminal

**Workaround:**
```
sudo apt install unzip
```

