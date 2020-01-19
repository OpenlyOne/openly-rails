# Openly One [inactive, not maintained]

[![GitHub release](https://img.shields.io/github/release/OpenlyOne/openly.svg)](https://github.com/OpenlyOne/openly)
[![Build Status](https://travis-ci.org/OpenlyOne/openly.svg?branch=master)](https://travis-ci.org/OpenlyOne/openly)
[![codecov](https://codecov.io/gh/OpenlyOne/openly/branch/master/graph/badge.svg)](https://codecov.io/gh/OpenlyOne/openly)

Openly is a collaboration platform for individuals and teams with bold
ambitions.

[Watch Introductory Video](https://www.youtube.com/watch?v=u3DAxi5PS6o&feature=youtu.be)

[Extended Intro Video](https://www.youtube.com/watch?v=4-UdCcaQE80&feature=youtu.be)

## Objective

Our objective is to develop a GitHub-like platform for Git-like version-control for projects that consist of documents (Word documents, Excel files, PowerPoint presentations).

## Background

Git is amazing. It's like a magical time machine for your work: You can track what you do, see changes, undo, work collaboratively and merge, and so much more.

GitHub is amazing as well. It's one of the biggest platforms for sharing and managing software projects and collaborating on code — especially for open source projects (one of our big passions!).

However, neither Git nor GitHub do very well with files that the "normal" working world uses: Word documents, Excel files, and PowerPoint presentations (to name a few commonly used ones). That is because these files are in a format called "binary", that makes it hard for programs to extract the contents from these files.

It's still possible to add these binary files to Git and GitHub. You will see when these files are changed, but you won't see what these changes were. You also cannot do any merging. It really takes the awesomeness out of Git.

## Introducing Openly

Openly is an attempt at bringing Git-like version control and a GitHub-like collaboration platform to document-based projects.

We are working to support all the features of Git and GitHub, especially diffs and merges, for files that the business world uses every day. Files such as .docx Word documents, .xlsx Excel spreadsheets, and .pptx PowerPoint presentations. By doing so, we hope to finally make version control and open source mainstream in the business community.

## How It Works

Openly is a mono-repo built on Ruby on Rails. It uses Postgres as a database.

#### Git-inspired Version Control System

We use a Git-inspired version control system. All the logic is abstracted into the `models/VCS` classes. There are repositories, branches, commits, etc.. All objects are stored in the database.

Initially, we used Rugged (Ruby bindings for Git). But Git had several limitations that made it difficult to use in the context of Google Drive. To name just one, Git is really based on the file system and having unique file names. Google Drive supports having many files with the same name in the same directory.

#### Google Drive Integration

For the moment, Openly only works with Google Drive.

Users can version control any Google Drive folder by giving edit access to that folder to our tracking account (track@open.ly) and creating a new repository from their account on www.open.ly.

This application runs a background queue (DelayedJob) that checks for file changes every ten seconds. We use the [Drive API v3: Changes: List](https://developers.google.com/drive/api/v3/reference/changes/list) endpoint for that.

Metadata for changed files is downloaded and stored in the database as a new version. A snapshot of the changed file is taken and stored in the respective repository archives (so that it can be restored later). We do this because it used to be impossible to get at the content of Google docs, sheets, and slides. This may have changed.

#### Diffing

So far, we only support diffing for text-based documents: Google docs, Open Office documents, Word documents, and PDF documents. We have our own diffing algorithm based on the `dwdiff` command that is excellent at identifying changes not only in text, but also in terms of whitespaces and linebreaks. See: `models/vcs/operations/content_differ.rb`

[Watch Video](https://www.youtube.com/watch?v=8S9dJWMKEfw)

#### Admin Dashboard

The application comes with an admin dashboard for managing users and projects. It is based on the excellent Administrate gem. The admin interface is available to admins only.

#### Analytics

We track actions (on the server-side) using Ahoy Matey and visualize them with Blazer.

#### Testing

The application is fully tested: on the unit level, on the integration level, on the end-to-end level. This is especially important to us. We are dealing with people's and organizations' documents and files here. We want to be confident that there is no chance of your data being lost whatsoever.

#### Backups

The application is set up to make automatic backups of the database (simple dumps) and uploaded assets (from Paperclip). This is invoked with `rake backup:all` and can be scheduled to run via CRON.

#### JavaScript

Early on, we made the decision to build a JavaScript-free application. We did this because it makes testing a lot easier. Our testing framework does not need to support JavaScript. It also makes SEO easier. We don't need a special set up for server-side rendering JavaScript, since we are just serving plain HTML.

Not using any JavaScript does have its price. It makes the application feel a little sluggish. And it also makes it difficult to implement real-time updates of counters, diffs, etc... If we were rewriting the application now, we would do so with the frontend in React and Rails as a backend.

## Setup

Copy `config/application.yml.example` to `config/application.yml` and fill in the various email addresses, keys, and secrets.

#### Google Drive API

Our app interacts heavily with the Google Drive API. You must create a Google application and [enable the Drive API](https://developers.google.com/drive/api/v3/enable-drive-api). You need to create an email account for tracking file changes and create an offline access token for that account.

Openly needs to know the email address of the Google account to use for
tracking changes. This account will be the one with whom version-controlled folders are shared. The account will be checking for file changes and it will also be the one that stores file snapshots in its Google Drive. It's super important.

In order for it to work, you need to authenticate that account against your application. Valid credentials for that user need to be present in the YAML file. The path to that file must be specified in `application.yml` under `GOOGLE_DRIVE_CREDENTIALS_PATH`.

This application does not help you to create that offline access token. But a script like the following can help:

```ruby
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'pry'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Drive API Ruby Quickstart'
# You must download this file from the Google Console
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "openly.yaml")
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  # The email address for which to generate a token for
  user_id = "exampleuser@gmail.com"
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

# Initialize the API
service = Google::Apis::DriveV3::DriveService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# The lines below are just for testing purposes, to check if everything
# worked.

# List the 10 most recently modified files.
response = service.list_files(page_size: 10,
                              fields: 'nextPageToken, files(id, name)')
puts 'Files:'
puts 'No files found' if response.files.empty?
response.files.each do |file|
  puts "#{file.name} (#{file.id})"
end

```

#### Server Setup

The application runs on a $10/month DigitalOcean VPS with 2GB Ram and 25GB disk space. The OS is Ubuntu 16.04.

Nginx setup:
```bash
upstream puma {
  server unix:///var/apps/openly/shared/tmp/sockets/openly-puma.sock;
}

server {
  listen 443 ssl;
  server_name www.open.ly;
  ssl_certificate /etc/letsencrypt/live/www.open.ly/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/www.open.ly/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/www.open.ly/fullchain.pem;
  ssl_dhparam /etc/ssl/certs/dhparam.pem;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers HIGH:!aNULL:!MD5;

  root /var/apps/openly/current/public;
  access_log /var/apps/openly/current/log/nginx.access.log;
  error_log /var/apps/openly/current/log/nginx.error.log info;

  location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  try_files $uri/index.html $uri @puma;
  location @puma {
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;

    proxy_pass http://puma;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 10M;
  keepalive_timeout 10;
}

# Redirect https requests from open.ly to www.open.lye
server {
  listen 443 ssl;
  server_name open.ly;
  ssl_certificate /etc/letsencrypt/live/open.ly/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/open.ly/privkey.pem;
  return 301 https://www.open.ly$request_uri;
}

# Redirect https requests from www.openly.one to www.open.ly
server {
  listen 443 ssl;
  server_name www.openly.one;
  ssl_certificate /etc/letsencrypt/live/www.openly.one/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/www.openly.one/privkey.pem;
  return 301 https://www.open.ly$request_uri;
}

# Redirect https requests from openly.one to www.open.ly
server {
  listen 443 ssl;
  server_name openly.one;
  ssl_certificate /etc/letsencrypt/live/openly.one/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/openly.one/privkey.pem;
  return 301 https://www.open.ly$request_uri;
}

# Redirect all http requests to https://www.open.ly/
server {
  listen 80 default_server;
  server_name _;

  return 301 https://www.open.ly$request_uri;
}

```

#### Cron Jobs

Output from `crontab -l`:

```bash
# Restart DelayedJob
@reboot RAILS_ENV=production /usr/local/rvm/bin/rvm default do /var/apps/openly/current/bin/delayed_job start

# Restart application
@reboot RAILS_ENV=production /usr/local/rvm/bin/rvm default do /var/apps/openly/current/bin/bundle exec puma -C /var/apps/openly/shared/puma.rb --daemon

# Backup database & attachments every day at 3am
0 3 * * * RAILS_ENV=production /usr/local/rvm/bin/rvm default do /var/apps/openly/current/bin/bundle exec rake -f /var/apps/openly/current/Rakefile backup:all
```

Output from `sudo crontab -l`:

```bash
47 1 * * 0 /usr/bin/certbot renew --post-hook "service nginx reload"
```


#### Background Queues (Delayed Job)

We have various jobs that run in the background (see `app/jobs`). The primary background job is the `file_update_job.rb` that pings the Google Drive API for changes every ten seconds.

#### Notification Emails (Mailjet)

We use [Mailjet](https://www.mailjet.com/) for sending transactional emails because of their generous free tier. The SMTP details need to be put into `application.yml`. But any service can be used. The email HTML and text is generated in-app with the help of [Inky](https://github.com/zurb/inky-rb).

#### Error Tracking (Rollbar)

We use [Rollbar](https://rollbar.com/) for tracking errors that happen in production. You will need to set up an account and generate an access token that you store in the `application.yml` file.
