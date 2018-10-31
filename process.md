---
layout: page
title: Project Process
---

**Goal:** to capture the current flow of research, product design and development, and test and release management. This is not meant to be exhaustive nor required necessarily, everything is subject to change in the spirit of agile and timeline-driven development.

<!-- TOC depthFrom:2 depthTo:4 withLinks:1 updateOnSave:1 orderedList:0 -->

- [User Story Creation](#user-story-creation)
- [Feasibility and Final Designs](#feasibility-and-final-designs)
- [Planning and Engineering](#planning-and-engineering)
	- [Development process overview](#development-process-overview)
	- [Agile process details](#agile-process-details)
		- [Waffle-based Kanban](#waffle-based-kanban)
		- [Estimation translation](#estimation-translation)
		- [GitHub labels](#github-labels)

<!-- /TOC -->

---

[![process](https://user-images.githubusercontent.com/49511/39437595-8d319a94-4c5e-11e8-9b63-bd511a3d6e70.png)](https://user-images.githubusercontent.com/49511/39437595-8d319a94-4c5e-11e8-9b63-bd511a3d6e70.png)
(click to see full size image)

## User Story Creation

Our intention is to lead the the Lockbox development process with research and user-oriented questions: what do we want or need to learn to achieve our product, business and user goals?

These questions or goals or features or experiments ultimately result in a GitHub issue ("user story") filed in the appropriate repository (e.g.: lockbox-extension for the browser extension, lockbox-ios for the iOS app).

The flow of a user story could roughly follow this flow:

- PM authors user story and provides acceptance criteria
- UX creates lo-fidelity designs to be reviewed by product team
- UX incorporates feedback
- user story is ready for engineering feasibility

## Feasibility and Final Designs

With a user story — including acceptance criteria and designs — there is opportunity for review and revisions:

- engineering reviews the story for feasibility, clarifying questions
- UX makes revisions
- UX creates final designs and assets
- final reviews and revisions completed

## Planning and Engineering

Once a user story is confirmed "ready" for engineering to implement (has final designs and approvals), it needs to be prioritized, estimated and scheduled. 

Some issues will be created outside of the above process and jump straight into this flow...

**All issues are automatically reflected on our Waffle.io kanban board used for our planning: [https://waffle.io/mozilla-lockbox/lockbox-extension](https://waffle.io/mozilla-lockbox/lockbox-extension)**

*As a group, during our sprint review session, we...*

* Review all **"Done"** items from the sprint and archive the cards

    * This allows review of what's been completed from a user perspective (demo).
    
    * This may flag the need for a follow-up discussion or issue for work to be completed.

*Before the sprint planning meeting, a pre-planning meeting is held by the product (and potentially involves other product or tech leads) to prioritize:*

* Triage items in the **"Inbox"** and advocate for any new work to be considered

    * "Inbox" will include all newly created issues across all repositories

    * If we haven't already, apply the proper labels (type of work, at the very least)

    * Move to "On Deck" if understood, labeled, ready for prioritizing (may still need details finalized, but agreed we want to do it)

*As a group, during our sprint planning (backloog grooming) session, we...*

* Review all **"In Progress"** items and see where they are at

    * Did they not make it into the milestone as expected?

    * Are there open items, blockers?
    
    * Should these items go back into the backlog for re-prioritization and planning?
		
* Review all **On Deck** items and consider promoting some or all of them into the **Backlog**

* Review all items in the **"Backlog"** and decide on this sprint's commitment:

    * These items are explicitly to be "committed" to for the current sprint (can be expected to be done, demo'd during the review)
		
    * We review the story and make sure its documented and understood so it can be committed to completing
		
    * Any dependencies (it depends on, or depends on something else) is reviewed and indicated
		
    * We also provide sizing guidance (how much work?) and see if anyone is specifically interested in working on it

### Development process overview

* "Take" an issue by assigning it to yourself if not obvious and consider moving it to "In Progress"

    * Open a PR with a meaningful title and description

    * Include "Fixes #" syntax in the PR description or in the commit messages

        * This will "attach" the PR to the Issue, and move it to "In Progress" if not already

    * Add "WIP" to the PR title if pushing up but not complete nor ready for review

* Request review from code owner(s), product, PI (as necessary)

    * Code owners are defined in `docs/` and automatically applied at PR creation

    * Code coverage must meet the guidelines or an exception must be explained

    * All other required commit statuses must pass (for example: CI tests), if any tests are broken it's the PR creator's responsibility to determine why and resolve it

  * Design review may result in changes to the PR or follow-up tasks to be addressed later

* Once the requested changes are made, you dismiss the previous reviews and re-request review (as noted above)

### Agile process details

#### Waffle-based Kanban

* **Inbox:** Everything starts here and pops onto the top of the stack. Items we've agreed are to be done get labeled and moved to On Deck.

* **On Deck:** Items that are prioritized and considered "stretch" goals to work on during the current sprint, likely to appear in the next one.

* **Backlog:** Items we've agreed we have everything we need to begin engineering work (requirements, designs, answers) and will commit to doing during the current sprint.

* **In Progress:** Work has started and typically a Pull Request has been created that "fixes issue #", linking the two items together. Testing, UX and code reviews happen here.

* **Done:** Once the issue (and PR) is closed, then the cards automatically move into this Done column. They're archived after sprint review.

#### Estimation translation

* `1` = hours

* `3` = day

* `5` = 2-3 days

...beyond that is too big.. make it an epic or break it down perhaps?

#### GitHub labels

**Priorities**

- `P1`: must have
- `P2`: nice to have
- `P3`: future consideration

**Issue Types**

* `bug`: something doesn't work as expected

* `feature` (enhancements): something new to build, design, test

* `tech-debt`: improvements we want to address that may not be user-facing

* `chore` (dev env, docs, etc.): other project related work

**Closed Issue Resolutions**

* `closed-duplicate`: addressed elsewhere

* `closed-invalid`: not an actual issue as described or applicable here

* `closed-wontfix`: not something we will address and not worth keeping open

**Open Questions or Help Needed**

* `needs-content`: final copy or text or decision needed before implementation

* `needs-design`: need new design or updates, assets

* `needs-eng`: need input or details from eng team before development, may be blocked on a pre-requisite task

* `needs-product`: decision or prioritization or input needed from PM

* `needs-research`: help inform approach, test/validate something

* `needs-tasks`: design and acceptance is provided, but more breakdown into work or tasks needed
