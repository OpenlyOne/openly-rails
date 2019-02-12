# CHANGELOG

## v0.35 (Feb 13, 2019)

**Enhancements:**
- Add support for premium accounts & make private projects a premium feature.
  Free users can only create public projects, while premium users can choose
  between public and private when creating the project.
- Improve the notification icon by replacing the old world icon with a bell
  icon. This should help more clearly identify it as a notification icon.
  ([#318](https://github.com/OpenlyOne/openly/issues/318))
- Improve placement of profile actions: Demote the edit profile button from
  floating action button to flat button. Add a button to create a new project
  as the primary action on the profile page. This should help solve the
  confusion of users who think they can create a project by clicking the button
  that actually takes them to the edit profile page
  ([#292](https://github.com/OpenlyOne/openly/issues/292))

**Fixes:**
- Do not show file diffs when plain text between two document version is the
  same
  ([#240](https://github.com/OpenlyOne/openly/issues/240))


## v0.34 (Feb 10, 2019)

**Enhancements:**
- Project preview cards have a new clean design
  ([#291](https://github.com/OpenlyOne/openly/issues/291))
- Project preview cards are now sorted by most recent commit and list that date
  ([#79](https://github.com/OpenlyOne/openly/issues/79))
- Project preview cards now indicate when the project has uncaptured changes
  and the capture changes button displays the number of uncaptured changes
  within the project
  ([#305](https://github.com/OpenlyOne/openly/issues/305))

**Fixes:**
- Private projects are no longer listed on the profile page unless the viewing
  user has the permission to view/collaborate on them
  ([#302](https://github.com/OpenlyOne/openly/issues/302))

## v0.33 (Feb 3, 2019)

**Features:**
- Users can create contributions. A contribution is essentially an isolated
workspace for that user to edit and modify copies of the original documents.
The project team can then review the suggested changes and accept the
contribution to apply the suggested changes to the original files in the
project. This feature is only available in select projects and is disabled by
default.

## v0.32.3 (Feb 3, 2019)

**Fixes:**
- Landing Page: Fix fonts on pricing table
- Landing Page: Fix footer alignment type

## v0.32.2 (Feb 3, 2019)

**Fixes:**
- Various fixes for the landing page:
  - Fix Google Analytics code
  - Fix fonts on pricing table
  - Fix footer alignment
  - Fix sizing of testimonials

## v0.32.1 (Feb 3, 2019)

**Fixes:**
- Fix images on landing page that prevented page from rendering.

## v0.32 (Feb 3, 2019)

**Enhancements:**
- Rework the landing page with a more modern design and new wording

**Fixes:**
- Fix a bug where admins could not search projects due to administrate trying
  to query a virtual attribute in the database.

## v0.31 (Jan 4, 2019)

**Features:**
- Admins can make projects public. Revisions, file infos, and archived files of
  public projects can be viewed by anyone. Work-in-progress (i.e. uncaptured
  changes) are visible to project collaborators only
  ([#251](https://github.com/OpenlyOne/openly/issues/251))

**Enhancements:**
- Projects can now be managed by admins via the admin panel
- Project collaborators can now be managed by admins via the admin panel
  ([#250](https://github.com/OpenlyOne/openly/issues/250))

## v0.30.2 (Dec 16, 2018)

**Fixes:**
- In folders view, generate correct links in the breadcrumbs/anecestry path by
  relying on #hashed_file_id ([#246](https://github.com/OpenlyOne/openly/issues/246))
- When force-syncing a folder, pull any new children as well as any children
  that have no current or committed version and can thus not be manually
  force-synced ([#247](https://github.com/OpenlyOne/openly/issues/247))

## v0.30.1 (Dec 6, 2018)

**Fixes:**
- Fix the latest database migration that was accidentally modified while doing
  a find-and-replace operation

## v0.30 (Dec 6, 2018)

**New Features:**
- Captured and uncaptured file content changes can now be opened on a dedicated
  page where they can be viewed side-by-side

**Enhancements:**
- Hashed file IDs are now used as primary routing parameter for the file infos
  page and the folders page. This makes the URLs stable across time,
  revisions, and branches (in the future). We still support the remote Google
  Drive file/folder ID as fallback.
- Henkei (our document text parser) now runs in server mode which has better
  performance

**Fixes:**
- Several lines of unused code has been removed
- Four VCS models have been renamed internally
- Migrations prior to August 1, 2018 have been squashed together
- Resources have been removed. Resources used to be links to individual Google
  documents/files. We tried them as a more lightweight alternative to
  repositories, to make it very easy for people to share resources with each
  other. We couldn't really get people to share any resources, so we decided to
  continue with our initial focus on repositories.

## v0.29.1 (Nov 24, 2018)

**Fixes:**
- Dereference source directory when backing up (Paperclip) attachments, so that
  the actual files are copied and not just a symlink
- On deployment, backup database and attachment before running migrations

## v0.29 (Nov 19, 2018)

**New Features:**
- Analytics dashboard for admin accounts for visualizing data like Monthly
  Active Users or number of files tracked

**Enhancements:**
- Database & (Paperclip) attachments are automatically backed up on deployment

**Fixes:**
- Notifications on the notifications page are now ordered in anti-chronological
  order (most recent first)
- Generation of the 500 server error page now works even when curl has to follow
  redirects

## v0.28 (Nov 16, 2018)

**Enhancements:**
- Grant archive access to project collaborators (and remove access when
  collaborators are removed)
- Replace logo with new bee logo and add 'beta' badge to navbar
- Improve logging by:
    - sharing logs between deployments
    - piping delayed job output to a dedicated delayed_job_production.log file
    - using Lograge to summarize log output

**Fixes:**
- The notifications page no longer crashes when one has notifications about new
  revisions
- Notification emails no longer have the old Upshift logo
- Upgrade rack gem to v2.0.6 to fix
  [CVE-2018-16471](https://nvd.nist.gov/vuln/detail/CVE-2018-16471) and
  [CVE-2018-16470](https://nvd.nist.gov/vuln/detail/CVE-2018-16470)
- Remove old models & specs (e.g. FileResource)

## v0.27.1 (Nov 13, 2018)

**Fixes:**
- When adding a file to a folder that once was present in a repository,
  FileUpdateJob no longer fails.

## v0.27 (Nov 8, 2018)

**New Features:**
- Users can see file content changes for text-based documents (Google Docs,
  Word .docx, Word .doc, Open Office .odt, and PDF) on revisions, capture
  changes, and file info pages

## v0.26.3 (Nov 7, 2018)

**Fixes:**
- Deleting projects is now possible again (it caused server errors due to the
  way that file thumbnails were implemented)

## v0.26.2 (Nov 6, 2018)

**Fixes:**
- Upgrade gem 'loofah' to address
  [CVE-2018-16468](https://nvd.nist.gov/vuln/detail/CVE-2018-16468)
- Add model specs for models added in v0.26
- Fix failing specs of models retired in v0.26
- Fix style violations introduced in v0.26

## v0.26.1 (Nov 1, 2018)

**Fixes:**
- Bump Capistrano version in deploy.rb to v3.11.0 (to reenable Capistrano CLI)

## v0.26 (Oct 31, 2018)

**New Features:**
- Users can restore snapshots of files from past revisions
- Users can roll back the project to a past revision

**Enhancements:**
- The application infrastructure was completely rewired to support branching and pull requests.

## v0.25.2 (Oct 23, 2018)

**Fixes:**
- Project setup: Replace sharing dialog image, so that it shows the correct
  tracking email address

## v0.25.1 (Oct 22, 2018)

**Fixes:**
- Uploading new versions of binary files now correctly show up as modified in
  Openly (since we are no longer force-casting version IDs to integers)

## v0.25 (Oct 22, 2018)

**New Features:**
- Files are automatically backed up whenever they are changed on Google Drive
- Users can travel back in time to past revisions and browse through their
  files and folders as they were at that point in time.

**Enhancements:**
- The color scheme is now 'blue darken-2' across the entire application

## v0.24 (Oct 8, 2018)

**Enhancements:**
- Improvements to the landing page: Column size, wording, compression

## v0.23 (Oct 4, 2018)

**Enhancements:**
- Complete makeover for the landing page to target Githubber as early adopters

## v0.22.1 (May 2, 2018)

**Fixes:**
- Fixed a bug where the Files and Revisions pages would break if they contained
  a PDF document

## v0.22 (April 25, 2018)

**New Features:**
- Add administration panel for admins to manage accounts and resources

## v0.21 (April 22, 2018)

**Fixes:**
- Rename application from 'Upshift' to 'Openly' (our new business name)

## v0.20 (April 14, 2018)

**New Features:**
- Profiles own resources (such as a Google Drive doc) that are listed on their
  profile page

## v0.19 (April 13, 2018)

**Enhancements:**
- Profiles have a location, social links, and one of 256 color schemes

## v0.18 (April 1, 2018)

**New Features:**
- When capturing changes, the user can (un-)select the file changes to capture.

## v0.17 (March 26, 2018)

**New Features:**
- Creating project revisions sends an in-app & email notification to your
  project team

**Enhancements:**
- The navigation bar now has icons rather than labels

**Fixes:**
- Header input fields when editing profile and project show correct color
  (white)

## v0.16.1 (March 20, 2018)

**Fixes:**
- Show file infos icon when hovering files

## v0.16 (March 20, 2018)

**Enhancements:**
- In file view, display thumbnails of files
- When trying to accessing a project without authorization, show custom error
  page
- When logging in, user is redirect back to previous page after successful
  authentication

**Fixes:**
- Background color is now gray lighten-4 on all browsers

## v0.15.3 (March 15, 2018)

**Fixes:**
- Collaborators can initiate project setup process

## v0.15.2 (March 15, 2018)

**Fixes:**
- In project setup, support different formats for Google Drive folder links

## v0.15.1 (March 14, 2018)

**Enhancements:**
- Can now create accounts by importing data from a CSV file.

## v0.15 (March 14, 2018)

**New Features:**
- When setting up project & importing files, show progress (# of files already
  imported) and commit all imported files at the end of the process.

## v0.14 (March 7, 2018)

**New Features:**
- Projects are private (viewable and accessible to owner and collaborators only)
  by default
- Analytics now keep track of page visits
- Files can be force synced from the files info page

**Enhancements:**
- Committing of changes is now referred to as 'Capturing Changes'
- Redid the project setup page to provide clearer and more detailed instructions

**Fixes:**
- Deleting projects now succeeds and no longer causes an error
- Error pages on post requests are now correctly displayed

## v0.13.2 (March 6, 2018)

**Fixes:**
- Reference ::File class in DriveService (not Providers::GoogleDrive::File)

## v0.13.1 (March 6, 2018)

**Fixes:**
- Remove `require 'factory_girl'` statement from rake tasks


## v0.13 (March 6, 2018)

**New Features:**
- Tracking of file renaming

**Enhancements:**
- Version control is supported by the database (PostgreSQL) rather than the file
  system (Git)

**Fixes:**
- Modification tracking is now limited to actual file changes. Previously, any
  type of action on a file (such as sharing it with someone) would result in it
  being shown as modified.

## v0.12 (January 29, 2018)

**New Features:**
- Users can add an about text to their profiles
- Project owners can add descriptions to their projects
- Project owners can add tags to their projects

**Enhancements:**
- Show collaborations (projects that a user collaborates in) on the user's
  profile page alongside projects that a user owns

**Fixes:**
- Upgrade 'paperclip' gem to v5.2.1 to patch vulnerability


## v0.11 (January 25, 2018)

**New Features:**
- Users can edit their profile and upload custom profile pictures.
- Users can choose to be remember on sign in, so that re-authentication is not
  required unless user is inactive for one week

**Fixes:**
- Labels no longer overlap their textareas even when Grammarly is used

## v0.10 (January 14, 2018)

**Internal:**
- Track errors in application and background jobs (in production) with Rollbar

## v0.9.1 (January 13, 2018)

**Fixes:**
- Links correctly open in current tab unless otherwise intended
- Upgrade 'nokogiri' gem to v1.8.1 to patch vulnerability

## v0.9 (January 13, 2018)

**New Features**:
- Files have an info page that shows their new changes as well as a revision
  history for just that file

**Changes**:
- Color scheme changed to 'blue darken-3'

**Fix**:
- Labels no longer be overlap their textareas
- Tab text is no longer be truncated

## v0.8.1 (January 10, 2018)

**Fix**:
- Delete migration related to dropping notification channels.


## v0.8 (January 10, 2018)

**New Features**:
- Users can commit changes in projects.
- Users can see the revision history of projects.
- Users can collaborate on projects.

## v0.7.1 (December 7, 2017)

**New Features**:
- Users can sign up to stay informed about Openly.

## v0.7 (November 25, 2017)

**New Features**:
- Reflect Google Drive file changes (addition, modification, rename,
  relocation, and deletion) in project files

## v0.6.1 (November 21, 2017)

- Fix: Support absolute file paths for Google Drive credentials file

## v0.6 (November 21, 2017)

**New Features**:
- Import a Google Drive Folder
- Browse folders and files imported from Google Drive

**Removals**:
- Version-Controlled Files (replaced with imported Google Drive files)
- Discussions & Replies (yet to be replaced with Google Drive comment
  integrations)


## v0.5 (October 17, 2017)

**New Features**:
- Discussions (Suggestions, issues, questions) and replies
- Makeover for project files: Design, add meta information (last contribution)
  and show file count in project head

**Fixes**:
- Remove top border from card title of card on the join page
- Specify width and height of logo in HTML (in addition to CSS)
- Remove margin between banner and text on the project's Overview page


## v0.4 (September 13, 2017)

**New Features**:
- Project file management

**Fixes**:
- Form elements with inherited styling will correctly show up as invalid if an
error occurs on the input element's attribute


## v0.3 (August 13, 2017)

**New Features**:
- Projects (with Version Control)

**Minor Changes**:
- Add favicon (Fixes #11)
- Redirect to login page when authentication is required (#24)

## v0.2 (August 7, 2017)

**New Features**:
- Registrations
- Account Management
- Sessions (login & logout)
- User profiles with handles (usernames)

**Minor Changes**:
- Remove JavaScript from application
- Add dynamic error pages (Fixes #12)
- Responsive font-size for headings

## v0.1.1 (July 30, 2017)

- Fix: Downgrade to Puma 3.8.1 ([Issue](https://github.com/seuros/capistrano-puma/issues/237))

## v0.1 (July 30, 2017)

- Initialize application
- Create landing page
- Set up deployment via Capistrano
