# WhatsApp Database --- Schema Design and Analysis

**Contributor:** Piyush Jaiswal\
**Schema:** `whatsapp`\
**Database used for verification:** `whatsapp_project`\
**Source schema:** `sql/01_schema.sql`\
**Dataset:** locally supplied CSV files in `seed_data/` (not committed
to Git)

## 1. Scope and verification approach

This document analyses the nine tables defined in `sql/01_schema.sql`.
The schema definitions were compared with the live PostgreSQL database,
and the supplied CSV data was loaded into the local `whatsapp` schema.
Column metadata, declared constraints, row counts, NULL patterns, and
integrity checks were queried from PostgreSQL.

The dataset directory and ZIP archive are excluded by `.gitignore`. They
are local inputs only and are not part of this documentation
deliverable.

## 2. Dataset row-count verification

All nine CSV imports completed successfully. The actual row counts match
the expected counts supplied for the project.

  Table                  Expected rows   Actual rows Result
  -------------------- --------------- ------------- -----------
  `users`                       30,000        30,000 Match
  `devices`                     42,000        42,000 Match
  `chats`                       23,000        23,000 Match
  `chat_members`               104,514       104,514 Match
  `media`                       27,634        27,634 Match
  `messages`                   120,000       120,000 Match
  `message_receipts`           501,590       501,590 Match
  `calls`                       25,000        25,000 Match
  `blocked_users`                4,000         4,000 Match
  **Total**                **877,738**   **877,738** **Match**

The total is the sum of rows across all nine tables; it counts records
in each relation, not distinct people or application-level entities.

## 3. Data dictionary

`NOT NULL` means the column cannot contain SQL NULL. A dash in the
default column means no explicit default was reported by
`information_schema.columns`. Primary-key columns are also non-null.

### 3.1 `users` --- 30,000 rows

  --------------------------------------------------------------------------------
  Column           PostgreSQL type  NULL?          Key / default  Purpose
                                                   / rule         
  ---------------- ---------------- -------------- -------------- ----------------
  `user_id`        `BIGINT`         No             PK             Unique user
                                                                  identifier

  `phone_e164`     `VARCHAR(20)`    No             UNIQUE         User phone
                                                                  number in
                                                                  E.164-style
                                                                  representation

  `display_name`   `VARCHAR(100)`   No             ---            Name shown to
                                                                  other users

  `about`          `TEXT`           Yes            ---            Optional profile
                                                                  description

  `is_business`    `BOOLEAN`        No             DEFAULT        Indicates
                                                   `FALSE`        whether the
                                                                  account is a
                                                                  business

  `joined_on`      `DATE`           No             ---            Date the user
                                                                  joined

  `last_seen_at`   `TIMESTAMPTZ`    Yes            ---            Most recent
                                                                  recorded
                                                                  activity time;
                                                                  may be
                                                                  unavailable or
                                                                  undisclosed

  `status`         `VARCHAR(20)`    No             CHECK:         Account state
                                                   `ACTIVE`,      
                                                   `BANNED`,      
                                                   `DELETED`      
  --------------------------------------------------------------------------------

### 3.2 `devices` --- 42,000 rows

  -------------------------------------------------------------------------------------
  Column             PostgreSQL type NULL?          Key / default /   Purpose
                                                    rule              
  ------------------ --------------- -------------- ----------------- -----------------
  `device_id`        `BIGINT`        No             PK                Unique registered
                                                                      device

  `user_id`          `BIGINT`        No             FK →              Owner of the
                                                    `users.user_id`   device

  `device_type`      `VARCHAR(20)`   No             CHECK: `ANDROID`, Device/platform
                                                    `DESKTOP`, `IOS`, category
                                                    `WEB`             

  `app_version`      `TEXT`          No             ---               Installed
                                                                      application
                                                                      version

  `registered_at`    `TIMESTAMPTZ`   No             ---               Device
                                                                      registration time

  `last_active_at`   `TIMESTAMPTZ`   No             ---               Most recent
                                                                      device activity
  -------------------------------------------------------------------------------------

### 3.3 `chats` --- 23,000 rows

  -------------------------------------------------------------------------------
  Column         PostgreSQL type  NULL?          Key / default /   Purpose
                                                 rule              
  -------------- ---------------- -------------- ----------------- --------------
  `chat_id`      `BIGINT`         No             PK                Unique chat
                                                                   identifier

  `chat_type`    `VARCHAR(10)`    No             CHECK: `DIRECT`,  Chat category
                                                 `GROUP`           

  `group_name`   `VARCHAR(100)`   Yes            CHECK: NULL for   Group title;
                                                 DIRECT and NOT    not applicable
                                                 NULL for GROUP    to direct
                                                                   chats

  `created_by`   `BIGINT`         No             FK →              User who
                                                 `users.user_id`   created the
                                                                   chat

  `created_at`   `TIMESTAMPTZ`    No             ---               Chat creation
                                                                   time
  -------------------------------------------------------------------------------

### 3.4 `chat_members` --- 104,514 rows

  --------------------------------------------------------------------------------------
  Column         PostgreSQL type NULL?          Key / default / rule     Purpose
  -------------- --------------- -------------- ------------------------ ---------------
  `chat_id`      `BIGINT`        No             Composite PK             Chat in which
                                                `(chat_id, user_id)`; FK the user
                                                → `chats.chat_id`        participates

  `user_id`      `BIGINT`        No             Composite PK             Participating
                                                `(chat_id, user_id)`; FK user
                                                → `users.user_id`        

  `role`         `VARCHAR(20)`   No             CHECK: `ADMIN`, `MEMBER` Member's role
                                                                         in the chat

  `joined_at`    `TIMESTAMPTZ`   No             ---                      Time the user
                                                                         joined

  `left_at`      `TIMESTAMPTZ`   Yes            CHECK: NULL or           Departure time;
                                                `left_at >= joined_at`   NULL represents
                                                                         no recorded
                                                                         departure

  `is_muted`     `BOOLEAN`       No             DEFAULT `FALSE`          Whether the
                                                                         member muted
                                                                         the chat
  --------------------------------------------------------------------------------------

The composite primary key prevents the same user from appearing more
than once in the same chat at a given time in this membership model.

### 3.5 `blocked_users` --- 4,000 rows

  ------------------------------------------------------------------------------------------
  Column         PostgreSQL type NULL?          Key / default / rule          Purpose
  -------------- --------------- -------------- ----------------------------- --------------
  `blocker_id`   `BIGINT`        No             Composite PK                  User who
                                                `(blocker_id, blocked_id)`;   initiated the
                                                FK → `users.user_id`          block

  `blocked_id`   `BIGINT`        No             Composite PK                  User who was
                                                `(blocker_id, blocked_id)`;   blocked
                                                FK → `users.user_id`          

  `blocked_at`   `TIMESTAMPTZ`   No             ---                           Time the block
                                                                              was recorded
  ------------------------------------------------------------------------------------------

CHECK constraint: `blocker_id <> blocked_id`, so a user cannot block
themselves.

### 3.6 `media` --- 27,634 rows

  -------------------------------------------------------------------------------
  Column          PostgreSQL type NULL?          Key / default /   Purpose
                                                 rule              
  --------------- --------------- -------------- ----------------- --------------
  `media_id`      `BIGINT`        No             PK                Unique media
                                                                   identifier

  `uploader_id`   `BIGINT`        No             FK →              User who
                                                 `users.user_id`   uploaded the
                                                                   media

  `media_type`    `VARCHAR(20)`   No             CHECK: `AUDIO`,   Media category
                                                 `DOCUMENT`,       
                                                 `IMAGE`, `VIDEO`  

  `mime_type`     `TEXT`          No             ---               MIME content
                                                                   type

  `size_bytes`    `BIGINT`        No             ---               Media size in
                                                                   bytes

  `sha256`        `TEXT`          No             ---               SHA-256
                                                                   content hash

  `uploaded_at`   `TIMESTAMPTZ`   No             ---               Upload time
  -------------------------------------------------------------------------------

### 3.7 `messages` --- 120,000 rows

  ----------------------------------------------------------------------------------------------
  Column                  PostgreSQL type NULL?          Key / default / rule     Purpose
  ----------------------- --------------- -------------- ------------------------ --------------
  `message_id`            `BIGINT`        No             PK                       Unique message
                                                                                  identifier

  `chat_id`               `BIGINT`        No             FK → `chats.chat_id`     Chat
                                                                                  containing the
                                                                                  message

  `sender_id`             `BIGINT`        No             FK → `users.user_id`     User who sent
                                                                                  the message

  `sent_at`               `TIMESTAMPTZ`   No             ---                      Message send
                                                                                  time

  `message_type`          `VARCHAR(20)`   No             CHECK: `AUDIO`,          Message
                                                         `DOCUMENT`, `IMAGE`,     category
                                                         `LOCATION`, `TEXT`,      
                                                         `VIDEO`                  

  `body`                  `TEXT`          Yes            ---                      Optional
                                                                                  textual
                                                                                  content or
                                                                                  caption

  `media_id`              `BIGINT`        Yes            FK → `media.media_id`    Optional
                                                                                  associated
                                                                                  media record

  `reply_to_message_id`   `BIGINT`        Yes            Self-FK →                Optional
                                                         `messages.message_id`    message being
                                                                                  replied to

  `is_forwarded`          `BOOLEAN`       No             DEFAULT `FALSE`          Whether the
                                                                                  message was
                                                                                  forwarded

  `is_deleted`            `BOOLEAN`       No             DEFAULT `FALSE`          Whether the
                                                                                  message is
                                                                                  marked deleted

  `edited_at`             `TIMESTAMPTZ`   Yes            CHECK: NULL or           Time of last
                                                         `edited_at >= sent_at`   edit, if
                                                                                  edited
  ----------------------------------------------------------------------------------------------

### 3.8 `message_receipts` --- 501,590 rows

  ------------------------------------------------------------------------------------------
  Column           PostgreSQL type NULL?          Key / default / rule        Purpose
  ---------------- --------------- -------------- --------------------------- --------------
  `message_id`     `BIGINT`        No             Composite PK                Message whose
                                                  `(message_id, user_id)`; FK receipt is
                                                  → `messages.message_id`     tracked

  `user_id`        `BIGINT`        No             Composite PK                Recipient
                                                  `(message_id, user_id)`; FK whose receipt
                                                  → `users.user_id`           is tracked

  `delivered_at`   `TIMESTAMPTZ`   Yes            ---                         Delivery time,
                                                                              if recorded

  `read_at`        `TIMESTAMPTZ`   Yes            CHECK: NULL or delivery is  Read time, if
                                                  NULL or                     recorded
                                                  `read_at >= delivered_at`   
  ------------------------------------------------------------------------------------------

### 3.9 `calls` --- 25,000 rows

  -------------------------------------------------------------------------------------------
  Column          PostgreSQL type NULL?          Key / default / rule          Purpose
  --------------- --------------- -------------- ----------------------------- --------------
  `call_id`       `BIGINT`        No             PK                            Unique call
                                                                               identifier

  `chat_id`       `BIGINT`        No             FK → `chats.chat_id`          Chat
                                                                               associated
                                                                               with the call

  `caller_id`     `BIGINT`        No             FK → `users.user_id`          User who
                                                                               initiated the
                                                                               call

  `call_type`     `VARCHAR(10)`   No             CHECK: `VOICE`, `VIDEO`       Call medium

  `started_at`    `TIMESTAMPTZ`   No             ---                           Call start
                                                                               time

  `answered_at`   `TIMESTAMPTZ`   Yes            CHECK: NULL or                Answer time,
                                                 `answered_at >= started_at`   if answered

  `ended_at`      `TIMESTAMPTZ`   Yes            CHECK: NULL or                End time, if
                                                 `ended_at >= started_at`      recorded

  `status`        `VARCHAR(20)`   No             CHECK: `COMPLETED`, `FAILED`, Call outcome
                                                 `MISSED`, `REJECTED`          
  -------------------------------------------------------------------------------------------

## 4. Primary keys, candidate keys and foreign-key relationships

### 4.1 Primary keys

  Table                Primary key
  -------------------- ----------------------------
  `users`              `user_id`
  `devices`            `device_id`
  `chats`              `chat_id`
  `chat_members`       `(chat_id, user_id)`
  `blocked_users`      `(blocker_id, blocked_id)`
  `media`              `media_id`
  `messages`           `message_id`
  `message_receipts`   `(message_id, user_id)`
  `calls`              `call_id`

### 4.2 Alternate candidate key

`users.phone_e164` is declared `UNIQUE` and `NOT NULL`. It is therefore
an alternate candidate key in addition to `user_id`, assuming the
application treats each phone number as identifying one user.

No other alternate candidate keys are asserted here unless they are
explicitly declared and verified.

### 4.3 Foreign-key relationships

  --------------------------------------------------------------------------------
  Child table and column           Referenced table and    Relationship
                                   column                  
  -------------------------------- ----------------------- -----------------------
  `devices.user_id`                `users.user_id`         One user can have
                                                           multiple devices

  `chats.created_by`               `users.user_id`         One user can create
                                                           multiple chats

  `chat_members.chat_id`           `chats.chat_id`         One chat can have
                                                           multiple members

  `chat_members.user_id`           `users.user_id`         One user can belong to
                                                           multiple chats

  `blocked_users.blocker_id`       `users.user_id`         A user can block
                                                           multiple users

  `blocked_users.blocked_id`       `users.user_id`         A user can be blocked
                                                           by multiple users

  `media.uploader_id`              `users.user_id`         One user can upload
                                                           multiple media records

  `messages.chat_id`               `chats.chat_id`         One chat can contain
                                                           multiple messages

  `messages.sender_id`             `users.user_id`         One user can send
                                                           multiple messages

  `messages.media_id`              `media.media_id`        A message can
                                                           optionally reference
                                                           media

  `messages.reply_to_message_id`   `messages.message_id`   A message can
                                                           optionally reply to
                                                           another message

  `message_receipts.message_id`    `messages.message_id`   One message can have
                                                           multiple recipient
                                                           receipts

  `message_receipts.user_id`       `users.user_id`         One user can have
                                                           multiple message
                                                           receipts

  `calls.chat_id`                  `chats.chat_id`         One chat can be
                                                           associated with
                                                           multiple calls

  `calls.caller_id`                `users.user_id`         One user can initiate
                                                           multiple calls
  --------------------------------------------------------------------------------

The `chat_members`, `blocked_users`, and `message_receipts` tables
resolve many-to-many or user-to-user relationships using composite
primary keys.

## 5. Functional dependencies

The following dependencies are supported by the declared primary keys.
`*` means all remaining non-key attributes in that table.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table                               Functional dependency
  ----------------------------------- ------------------------------------------------------------------------------------------------------------------------------------
  `users`                             `user_id → phone_e164, display_name, about, is_business, joined_on, last_seen_at, status`; also
                                      `phone_e164 → user_id, display_name, about, is_business, joined_on, last_seen_at, status` because `phone_e164` is UNIQUE and NOT
                                      NULL

  `devices`                           `device_id → user_id, device_type, app_version, registered_at, last_active_at`

  `chats`                             `chat_id → chat_type, group_name, created_by, created_at`

  `chat_members`                      `(chat_id, user_id) → role, joined_at, left_at, is_muted`

  `blocked_users`                     `(blocker_id, blocked_id) → blocked_at`

  `media`                             `media_id → uploader_id, media_type, mime_type, size_bytes, sha256, uploaded_at`

  `messages`                          `message_id → chat_id, sender_id, sent_at, message_type, body, media_id, reply_to_message_id, is_forwarded, is_deleted, edited_at`

  `message_receipts`                  `(message_id, user_id) → delivered_at, read_at`

  `calls`                             `call_id → chat_id, caller_id, call_type, started_at, answered_at, ended_at, status`
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Foreign-key columns do not by themselves imply functional dependencies
from the referenced key to the child table's non-key attributes. The
dependencies above are based on declared keys; additional business
dependencies should only be added if established by the application
rules.

## 6. Normalization analysis

This analysis is based on the declared relational structure and key
dependencies. It does not claim to prove every possible business-rule
dependency that may exist outside the schema.

### 6.1 First Normal Form (1NF)

The tables use individual columns for attributes and define no repeating
groups or nested relation-valued columns. The design therefore satisfies
the structural requirements of 1NF, assuming values supplied in each
field are atomic for the application's purposes.

### 6.2 Second Normal Form (2NF)

Tables with single-column primary keys (`users`, `devices`, `chats`,
`media`, `messages`, and `calls`) cannot have partial dependencies on a
proper subset of their primary key.

For the composite-key tables: - `chat_members`: membership-specific
attributes (`role`, `joined_at`, `left_at`, `is_muted`) depend on the
combination `(chat_id, user_id)`. - `blocked_users`: `blocked_at`
depends on the pair `(blocker_id, blocked_id)`. - `message_receipts`:
`delivered_at` and `read_at` depend on `(message_id, user_id)`.

No partial dependencies are indicated by the declared design, so these
tables satisfy 2NF under the stated functional dependencies.

### 6.3 Third Normal Form (3NF)

The design separates attributes about users, devices, chats, messages,
media, calls, membership, blocking, and receipts into their respective
relations. The declared key dependencies do not indicate non-key
attributes determining other non-key attributes. The design is therefore
consistent with 3NF under the functional dependencies documented above.

For example, device details are stored in `devices` rather than repeated
in `users`, and media metadata is stored in `media` rather than
duplicated in every message.

### 6.4 Boyce-Codd Normal Form (BCNF)

The declared key-based dependencies have candidate keys as determinants:
the primary keys and the verified alternate key `users.phone_e164`. On
the dependencies established from the schema, the relations are
consistent with BCNF.

This is a schema-based assessment, not proof against every possible
additional business dependency. If further dependencies are discovered
(for example, rules involving combinations of message type and media
type), they should be evaluated separately.

## 7. NULL-value analysis

The following counts were measured from the loaded dataset. NULL is
interpreted in context; it does not automatically mean invalid or
missing data.

  -----------------------------------------------------------------------------------------------
  Table                Column                        Total rows        NULL rows Interpretation
  -------------------- ----------------------- ---------------- ---------------- ----------------
  `users`              `about`                           30,000           11,949 Optional profile
                                                                                 description

  `users`              `last_seen_at`                    30,000              624 Last-seen time
                                                                                 may be
                                                                                 unavailable or
                                                                                 undisclosed

  `chats`              `group_name`                      23,000           20,000 All 20,000
                                                                                 direct chats
                                                                                 have NULL group
                                                                                 names

  `chat_members`       `left_at`                        104,514           98,213 No departure
                                                                                 time recorded
                                                                                 for these
                                                                                 memberships

  `messages`           `body`                           120,000           25,827 Body is
                                                                                 optional;
                                                                                 interpretation
                                                                                 depends on
                                                                                 message type

  `messages`           `media_id`                       120,000           92,923 Most messages do
                                                                                 not reference
                                                                                 media

  `messages`           `reply_to_message_id`            120,000          105,090 Most messages
                                                                                 are not replies

  `messages`           `edited_at`                      120,000          117,327 Most messages
                                                                                 have no recorded
                                                                                 edit time

  `message_receipts`   `delivered_at`                   501,590            5,076 Delivery time is
                                                                                 not recorded for
                                                                                 these receipts

  `message_receipts`   `read_at`                        501,590          129,242 These receipts
                                                                                 have no recorded
                                                                                 read time

  `calls`              `answered_at`                     25,000           10,022 No answer time
                                                                                 recorded; may
                                                                                 represent
                                                                                 unanswered calls

  `calls`              `ended_at`                        25,000            1,282 No end time
                                                                                 recorded for
                                                                                 these calls
  -----------------------------------------------------------------------------------------------

### 7.1 Direct and group chat names

The data was grouped by `chat_type`:

  Chat type     Total chats   NULL group names   Non-NULL group names
  ----------- ------------- ------------------ ----------------------
  `DIRECT`           20,000             20,000                      0
  `GROUP`             3,000                  0                  3,000

This exactly matches the CHECK constraint: direct chats must have
`group_name IS NULL`, while group chats must have a non-NULL group name.
These NULLs are intentional, not data-quality failures.

### 7.2 Message media observations

The message-type breakdown was:

  Message type     Total messages   `media_id` NULL
  -------------- ---------------- -----------------
  `AUDIO`                   7,178               163
  `DOCUMENT`                3,665                72
  `IMAGE`                  12,121               236
  `LOCATION`                2,391             2,391
  `TEXT`                   89,975            89,975
  `VIDEO`                   4,670                86

All 92,366 `TEXT` and `LOCATION` messages have no media reference in
this dataset. A further 557 messages of media-oriented types (`AUDIO`,
`DOCUMENT`, `IMAGE`, `VIDEO`) have NULL `media_id`. These 557 records
are observations worth reviewing against application rules; the schema
currently permits them because `media_id` is nullable.

## 8. Integrity checks

Six checks were executed against the loaded data. Each returned zero
violations.

  --------------------------------------------------------------------------------
  Check                                      Violation count Interpretation
  ----------------------------- ---------------------------- ---------------------
  Self-blocking users                                      0 No user blocks
  (`blocker_id = blocked_id`)                                themselves

  Chat member departure before                             0 All recorded
  joining                                                    departure times are
                                                             on or after join
                                                             times

  Calls answered or ended                                  0 Call timestamps
  before starting                                            satisfy the checked
                                                             ordering rules

  Messages edited before                                   0 All recorded edit
  sending                                                    times are on or after
                                                             send times

  Receipts read before delivery                            0 Where both timestamps
                                                             exist, read time is
                                                             not earlier than
                                                             delivery time

  Chat group-name rule                                     0 Direct/group chat
  violations                                                 names follow the
                                                             schema rule
  --------------------------------------------------------------------------------

These checks correspond to rules represented by CHECK constraints in the
schema. The zero counts confirm that the currently loaded rows satisfy
those tested conditions.

### 8.1 Message/media type consistency

A join between `messages` and `media` grouped by `message_type` and
`media_type` returned:

  Message type   Media type     Matching records
  -------------- ------------ ------------------
  `AUDIO`        `AUDIO`                   7,015
  `DOCUMENT`     `DOCUMENT`                3,593
  `IMAGE`        `IMAGE`                  11,885
  `VIDEO`        `VIDEO`                   4,584

All 27,077 messages that have a non-NULL `media_id` matched the
corresponding `media.media_type` in the observed dataset. However, the
current schema does not declare a constraint that enforces equality
between `messages.message_type` and `media.media_type`. This is an
observed data property, not a database-enforced guarantee.

## 9. Derived and potentially redundant attributes

-   **Chat member counts:** A member count can be derived by counting
    rows in `chat_members` for a `chat_id`. Storing a separate count
    would introduce a value that must be maintained when membership
    changes.
-   **Unread counts:** An unread count can be derived from message
    receipts and their `read_at` values, subject to the application's
    definition of unread. Storing it redundantly can create update
    anomalies.
-   **Call duration:** When both `started_at` and `ended_at` are
    available, duration can be calculated as `ended_at - started_at`. It
    need not be stored as an independent value unless required for
    performance or historical reporting.
-   **Message/media type:** `messages.message_type` and
    `media.media_type` describe related classifications. Their values
    matched for every attached media record in this dataset, but the
    schema does not enforce this cross-table rule. Application
    validation or a suitable database design change would be needed if
    this must always hold.
-   **Unread/read state:** `read_at` being NULL can be used as part of
    an unread-state calculation, but only with the application's receipt
    and recipient rules. It is not necessarily a universal unread
    counter by itself.

## 10. Constraint summary and design observations

The live PostgreSQL catalog reported 40 declared constraints of types
PRIMARY KEY, FOREIGN KEY, UNIQUE, and CHECK across the `whatsapp`
schema. In addition, column metadata reports NOT NULL requirements and
defaults.

Notable constraints include: - `users.phone_e164` is UNIQUE. -
`chat_members`, `blocked_users`, and `message_receipts` have composite
primary keys. - `messages.reply_to_message_id` is a self-referencing
foreign key. - `chats` has a CHECK rule connecting `chat_type` and
`group_name`. - Temporal CHECK rules protect membership, call,
message-edit, and receipt timestamp ordering. - Type/status CHECK rules
restrict accepted values for users, devices, chats, media, messages, and
calls. - `blocked_users` prevents a user from blocking themselves.

The schema does not currently enforce every possible business rule. In
particular, it does not enforce that a message's `message_type` agrees
with its referenced media's `media_type`, nor does the schema itself
establish all possible application-level rules about which users may
receive receipts or participate in calls.

## 11. Reproducibility and scope notes

-   The database used for this analysis was the local PostgreSQL
    database `whatsapp_project`, with tables under schema `whatsapp`.
-   The nine CSV files were imported locally using `\copy`; each import
    reported the row count listed in Section 2.
-   The analysis used catalog queries against `information_schema` and
    `pg_constraint`, plus aggregate queries against the loaded tables.
-   The dataset files are excluded by `.gitignore` (`seed_data/`,
    `seed_data.zip`, and `large_data/`) and must not be committed.
-   This document describes the existing schema. It does not claim that
    additional indexes or unimplemented constraints exist.
