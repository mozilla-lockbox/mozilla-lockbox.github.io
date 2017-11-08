# Lockbox

This website is to gather documentation and details for Mozilla's experimental
[Lockbox product][website]. Lockbox will be the framework for us to test and
quickly iterate on hypotheses (on desktop and mobile) without disrupting
existing Firefox users relying on the “saved logins” feature.

All planning and work performed is reflected on our Waffle.io kanban board:  
[https://waffle.io/mozilla-lockbox/lockbox-extension](https://waffle.io/mozilla-lockbox/lockbox-extension)

## Product Components

Here are links to the in-progress projects that make up the Lockbox experiment.

Component                                       | Documentation
---                                             | :---:
[Data Store :unlock: ][datastore-repo]          | [:scroll:][datastore-docs]
[Firefox extension :computer:][extension-repo]  | [:scroll:][extension-docs]
[iOS application :iphone: ][ios-repo]           |
[Project documentation :scroll:][docs-repo]     | [:scroll:][website]

This is not exhaustive nor a guarantee of any future plans but meant as a
helpful reference.

## Project Processes

**Goal:** to capture the current flow of research, product design and development, and test and release management, primarily in context of the Lockbox browser extension. Once agreed on the draft process, it can serve as our model to change and improve. This is not meant to be exhaustive nor required necessarily, everything is subject to change in the spirit of agile and timeline-driven development.

<!-- TOC depthFrom:3 depthTo:3 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Research, Product & UX Stories](#research-product-ux-stories)
- [Sprint & Development Planning (2 weeks)](#sprint-development-planning-2-weeks)
- [Development, Testing & Release Process](#development-testing-release-process)

<!-- /TOC -->

### Research, Product & UX Stories

**Overview:** Our intention is to lead the the Lockbox development process with research and user-oriented questions: what do we want or need to learn to achieve our product, business and user goals? These questions or goals or features or experiments ultimately result in a GitHub issue filed in the appropriate repository (lockbox-extension for the Firefox extension, lockbox-ios for the iOS app).

_Note: first search for existing / related issues, so as to not create duplicates and maintain history._

* In GitHub (not Bugzilla), anyone can create a new (or edit an existing) issue

    * Set a meaningful title (no worries, anyone can change it later)

    * Provide user and product context, requirements, and designs in the description

    * Apply the 'feature' and 'backlog' labels in GitHub

        * If the work becomes too big for one issue, this will become an 'epic' and separate issues will be created for the work to be prioritized

* Apply the 'need-research' label for all features that need input from user research

    * For example, "password management" may originate from engineering and product requirements and after built, require research to learn if what was built is better/faster than an alternative

    * Note: there may be separate 'need-research' issues / checklists created as well for innovative or generative exploration. For example, "password generation" may start with user research studies in order to then inform and update the issue description with requirements, recommendations, designs

* Some issues may be created and require design ('need-ux')

    * Once the prerequisites are completed (research explored, design created, user voice added, acceptance criteria defined, content created, etc.) and the issue is updated with the requirements, then it's ready to move from the Backlog to the "To Do" list for engineering to be assigned and implement the work

    * Some issues are minor, self-contained and will be created and go straight to "Backlog" for prioritization and "To Do" without the UR or UX team involved

![issue-creation-approach](https://user-images.githubusercontent.com/49511/32564064-3dbdfc62-c470-11e7-8648-ad088c1fa511.png)


### Sprint & Development Planning (2 weeks)

**Overview:** Once a feature is confirmed ready to build (see process above), it needs to be prioritized, potentially discussed, and then estimated and scheduled for implementation. Some issues will be created outside of the above process and jump straight into this flow. This is how we, as a core team, agree what our two-week plan is.


**All issues are automatically reflected on our Waffle.io kanban board used for our planning: [https://waffle.io/mozilla-lockbox/lockbox-extension](https://waffle.io/mozilla-lockbox/lockbox-extension)**

![kanban-board-flow](https://user-images.githubusercontent.com/49511/32564066-3de1ba62-c470-11e7-99e9-d347c6ce8548.png)

As a group, during our planning sessions, we...

* Review all **"Done"** items from the sprint and archive the cards

    * This allows the PI and Analytics team to passively double check everything they're expecting has been tested or tracked (or may flag the need for a follow-up discussion or issue for work to be completed).

    * This also allows the entire team including product, research, and engineering to understand and celebrate the work complete from the past sprint.

* Review all **"In Progress"** items and see where they are at

    * Did they not make it into the milestone as expected?

    * Are there open items, blockers?

Once we're clear on what's done and what's remaining from the sprint…

* Triage all the issues in the **"Inbox"**

    * "Inbox" will include all newly created issues across all repositories

    * It will also include external contributions (PRs) and issues created

        * responsibility to respond to external contributors?

        * decide: voice, how much planning/detail is shared, etc.?

    * If we haven't already, apply the proper labels (type of work, at the very least)

    * Agree as a team to

        * "Close" with an explanation and resolution

        * "leave in Inbox to review later" if no immediate decision

        * "move to "Backlog" if understood, labeled, ready for prioritizing (may still need details finalized, but agreed we want to do it)

* Review all items in the **"Backlog"** and decide if any should be promoted to work on

    * An effort estimate should be applied so we know how big the work is

    * Some open questions may remain at this point but can be answered as we go

* Review all **"To Do"** items and prioritize

    * Anything moved from "Backlog" to "To Do" is assumed part of the milestone

    * Has anything we already prioritized become more or less important to do?

    * Do we know who is working on what? What blockers or questions remain? Follow up conversations or details needed to get started?

#### Use of Waffle.io kanban board columns

* **Inbox:** Everything starts here and pops onto the top of the stack including external contributor PRs. Items we've agreed are to be done get labeled and moved to the Backlog.

* **Backlog:** Once agreed we have what we need to work on (requirements, designs, answers) we move Backlog items to "To Do" and provide an "effort" estimate.

* **To Do:** We work on items from the top and down the stack. Milestones are applied to make sure we know what we aim to ship in the two-week cycle.

* **In Progress:** Work has started and typically a Pull Request has been created that "fixes the issue, linking the two items together. PI and testing review happen here.

* **Done:** Once the issue is closed (and PR) then the cards automatically move into this Done column which can be reviewed every two weeks for what was accomplished.

##### Use of Waffle.io estimations (added at Backlog, or To Do):

* **1** = hours

* **3** = day

* **5** = 2-3 days

* beyond that is too big.. make it an epic or break it down perhaps?

#### Organizing and using GitHub labels

##### Issue Types

* epic: organize multiple issues, no work done here, closed by product and PI

* bug: something doesn't work as expected

* feature (enhancements): something new to build, design, test

* chore (dev env, docs, etc.): other project related work

* TxP: Test Pilot specific planning todos, from them or for them

##### Closed Issue Resolutions

* closed-wontfix: not something we will address and not worth keeping open

* closed-invalid: not an actual issue as described or applicable here

* closed-duplicate: addressed elsewhere

    * also add "Duplicate of #" in GitHub issue comment to link issue

* pi-verified: applied by PI team after an item has been tested, documented, reviewed

##### Open Questions or Help Needed

* needs-ux: need design or prototype or decision from UX/UI team

* needs-research: help inform approach, test/validate something

* needs-pi: need input on design or confirmation, immediate or special attention needed

* needs-eng: need input or details from eng team before development (in planning)

* question: generally needs to be discussed and defined as a group, decision missing

##### Use of GitHub milestones

* Apply Milestone once moved from "Backlog" to "To Do"

* "To Do" implies we will do it within the current/next milestone

* Semver describes numbering scheme (0.1.1-alpha, 0.1.3-alpha2)

##### Defining priorities (TBD)

- p1-must-have
- p2
- p3

### Development, Testing & Release Process

* "Take" an issue by assigning it to yourself if not obvious and consider moving it to "In Progress"

    * Open a PR with a meaningful title and description

    * Include "Fixes #" syntax in the PR description or in the commit messages

        * This will "attach" the PR to the Issue, and move it to "In Progress" if not already

    * Add "WIP" to the PR title if pushing up but not complete nor ready for review

* Request code review from code owner(s) and PI team

    * Code owners are defined in `docs/` and automatically applied at PR creation

    * PI monitors all opened items and uses "pi-verified" to confirm item has been reviewed or captured in tests, depending on what applies after-the-fact

    * The "pi-needed" label is applied if input from PI is needed or special attention before merging the feature

    * Code coverage must meet the guidelines or an exception must be explained

    * All other required commit statuses must pass (for example: CI tests), if any tests are broken it's the PR creator's responsibility to determine why and resolve it

* Code freeze / "pencils down" at the end of the Thursday before end of sprint for PI end-to-end testing

    * Product and engineering collaborate on the release notes throughout the cycle

    * Friday morning: PI reviews a Pull Request that includes all items on "master" branch against "production" branch

        * Master is assumed to be deploy-able, production is actually live and available for download / update to users

    * Friday: Once approved by PI and end-to-end tests passed, Pull Request to "production" is ready to merge on Monday

        * After PI has passed, any additions/merges to master *may not* get deployed to production as part of this release. Exceptions must be approved by the engineering, PI, and product teams.

    * Monday morning: release engineer merges the master-to-production PR and follows remainder of the release instructions


---

[website]: https://mozilla-lockbox.github.io/
[datastore-repo]: https://github.com/mozilla-lockbox/lockbox-datastore
[datastore-docs]: https://mozilla-lockbox.github.io/lockbox-datastore/
[extension-repo]: https://github.com/mozilla-lockbox/lockbox-extension
[extension-docs]: https://mozilla-lockbox.github.io/lockbox-extension/
[ios-repo]: https://github.com/mozilla-lockbox/lockbox-ios
[docs-repo]: https://github.com/mozilla-lockbox/mozilla-lockbox.github.io/
