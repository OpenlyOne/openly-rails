# CHANGELOG

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
