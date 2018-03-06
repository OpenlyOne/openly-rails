# CHANGELOG


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
- Users can sign up to stay informed about Upshift.

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
