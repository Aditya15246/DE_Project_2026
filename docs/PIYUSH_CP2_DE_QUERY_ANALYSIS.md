# CP2 — Piyush's Query Execution Plan Analysis

## R17 — Message Read Response Time by Message Type

- **Run times (ms):** 27.839 / 21.001 / 18.286
- **Average (ms):** 22.375
- **Main plan nodes:** Parallel Sequential Scan, Parallel Hash Join, Partial Hash Aggregate, Gather Merge, Finalize Group Aggregate, Sort.
- **Tables:** `message_receipts`, `messages`.
- **Plan evidence:**
  - `message_receipts` processes approximately 124,116 rows per worker.
  - 43,081 rows per worker are removed by the `read_at IS NOT NULL` filter.
  - `messages` processes approximately 2,198 rows per worker, with 37,802 rows removed by the date filter.
  - Parallel Hash Join joins both tables using `message_id`.
  - Final aggregation produces 6 groups.
  - Approximately 5,137 shared buffers are hit.
- **Likely cost driver:** Scanning and filtering large portions of both tables, followed by hash joining and aggregation. Parallel execution helps reduce processing time.

## R18 — Inactive Users in Group Chats

- **Run times (ms):** 16.417 / 15.738 / 15.319
- **Average (ms):** 15.825
- **Main plan nodes:** Sequential Scan, Hash Join, Hash Semi Join, Sort.
- **Tables:** `users`, `chat_members`, `chats`.
- **Plan evidence:**
  - The `users` scan processes 6,794 rows and removes 23,206 rows through filtering.
  - The `chat_members` scan processes 98,213 rows and removes 6,301 rows.
  - The `chats` scan processes 3,000 group chats and removes 20,000 non-group chats.
  - Hash Join produces 58,213 rows before the Hash Semi Join.
  - Final output contains 6,097 rows.
  - Sorting is performed using `last_seen_at`.
- **Likely cost driver:** Full-table scans across three tables and hash-based joins. The large intermediate result from `chat_members` contributes significantly to execution work.

## R19 — Group Chat Message Activity Analysis

- **Run times (ms):** 15746.260 / 15960.766 / 16342.906
- **Average (ms):** 16016.644
- **Main plan nodes:** Sequential Scan, SubPlan, Aggregate, Sort.
- **Tables:** `chats`, `messages`.
- **Plan evidence:**
  - The `chats` scan processes 3,000 group chats and removes 20,000 non-group chats.
  - Two correlated subplans execute 3,000 times each.
  - The first subplan performs a sequential scan on `messages`, processing 24 matching rows and removing 119,976 rows per execution.
  - The second subplan processes 1 matching row and removes 119,999 rows per execution.
  - Each subplan generates approximately 4,512,000 shared buffer hits across its repeated executions.
  - Total buffer hits are approximately 9,024,179.
  - The final result sorts 3,000 group chats.
- **Likely cost driver:** Repeated correlated subqueries are the primary performance bottleneck. Both subplans repeatedly scan the entire `messages` table for each of the 3,000 group chats. This causes millions of buffer accesses and extremely high execution time.

## R20 — Hourly Message Distribution by Message Type

- **Run times (ms):** 46.686 / 48.592 / 50.026
- **Average (ms):** 48.435
- **Main plan nodes:** Sequential Scan, Sort, GroupAggregate.
- **Tables:** `messages`.
- **Plan evidence:**
  - Sequential Scan processes all 120,000 messages.
  - Sorting is performed using extracted hour and `message_type`.
  - Sort Method is external merge.
  - Approximately 2,392 kB of temporary disk space is used.
  - Temporary buffers show 299 blocks read and 300 written.
  - Final aggregation produces 144 groups.
- **Likely cost driver:** Scanning all messages and sorting 120,000 rows. The external merge sort requires temporary disk I/O, increasing execution time before aggregation.

## R21 — Message Count by Message Type

- **Run times (ms):** 13.118 / 12.694 / 12.487
- **Average (ms):** 12.766
- **Main plan nodes:** Sequential Scan, HashAggregate, Sort.
- **Tables:** `messages`.
- **Plan evidence:**
  - Sequential Scan processes all 120,000 messages.
  - HashAggregate groups messages by `message_type`.
  - Aggregation produces 6 groups.
  - Hash aggregation uses approximately 24 kB of memory.
  - A final quicksort orders the 6 groups.
  - Approximately 1,507 shared buffers are hit.
- **Likely cost driver:** The full-table scan of 120,000 messages is the main processing operation. Aggregation and sorting are relatively inexpensive because only 6 groups are produced.

## R22 — Latest Messages with Pagination

- **Run times (ms):** 13.784 / 8.442 / 8.543
- **Average (ms):** 10.256
- **Main plan nodes:** Index Scan Backward, Limit.
- **Tables:** `messages`.
- **Plan evidence:**
  - PostgreSQL uses `messages_pkey` for a backward index scan.
  - The index scan produces 100,025 rows.
  - The Limit node returns 25 rows.
  - The first execution reads 258 disk blocks, while subsequent executions use shared-buffer cache hits.
- **Likely cost driver:** Although the primary-key index is used, the index scan processes 100,025 rows before the Limit returns 25. The large number of index entries traversed contributes to execution time.

## R23 — Inactive Web and Desktop Devices

- **Run times (ms):** 3.929 / 3.860 / 3.773
- **Average (ms):** 3.854
- **Main plan nodes:** Sequential Scan, Sort.
- **Tables:** `devices`.
- **Plan evidence:**
  - Sequential Scan processes 42,000 device records.
  - 6,945 rows satisfy the device type and last-active-date filters.
  - 35,055 rows are removed by the filter.
  - The resulting rows are sorted by `last_active_at`.
  - Quicksort uses approximately 518 kB of memory.
  - Approximately 396 shared buffers are hit.
- **Likely cost driver:** The full-table scan and filtering of device records are the main operations. Sorting is relatively inexpensive due to the smaller filtered result.

## R24 — Duplicate Media Detection

- **Run times (ms):** 8.114 / 8.059 / 8.133
- **Average (ms):** 8.102
- **Main plan nodes:** Sequential Scan, HashAggregate, Sort.
- **Tables:** `media`.
- **Plan evidence:**
  - Sequential Scan processes all 27,634 media records.
  - HashAggregate groups records by `sha256`.
  - The `count(*) > 1` filter removes 24,371 groups.
  - Only 48 groups remain in the final result.
  - Hash aggregation uses approximately 6,929 kB of memory.
  - The remaining results are sorted by count in descending order.
- **Likely cost driver:** Scanning the complete media table and performing hash aggregation to identify duplicate hashes. The grouping operation consumes more memory than the final sorting operation.

## R25 — Recursive Message Reply Thread

- **Run times (ms):** 0.054 / 0.058 / 0.051
- **Average (ms):** 0.054
- **Main plan nodes:** Recursive Union, Index Scan, Nested Loop, WorkTable Scan, CTE Scan, Sort.
- **Tables:** `messages`.
- **Plan evidence:**
  - The recursive CTE starts with an Index Scan on `messages_pkey`.
  - The initial lookup uses `message_id = 119989`.
  - Recursive processing uses Nested Loop and WorkTable Scan.
  - Additional message lookups use the primary-key index.
  - Only 3 rows are produced by the recursive CTE.
  - Approximately 15 shared buffers are hit.
- **Likely cost driver:** There is no significant performance bottleneck. The primary-key index enables efficient message lookups, and the recursive operation processes only three records.

---

## 2. Write queries (W03–W05)

## W03 — Update Message Record

- **Run times (ms):** 0.580 / 0.481 / 0.286
- **Average (ms):** 0.449
- **Main plan nodes:** Update, Index Scan.
- **Target table:** `messages`.
- **Plan evidence:**
  - Update operation targets the `messages` table.
  - Index Scan uses `messages_pkey`.
  - The lookup condition is `message_id = 119989`.
  - Only one matching row is retrieved.
  - Approximately 35–36 shared buffers are hit, with one buffer dirtied in the first execution.
- **Likely cost driver:** No major bottleneck is observed. The primary-key index enables direct retrieval of the target record, making the update efficient.

## W04 — Bulk Insert Message Receipts

- **Run times (ms):** 56.683 / 34.807 / 26.314
- **Average (ms):** 39.268
- **Main plan nodes:** Insert, Function Scan, Foreign Key Constraint Triggers.
- **Target table:** `message_receipts`.
- **Plan evidence:**
  - The query inserts 5,000 rows using `generate_series`.
  - Conflict resolution uses `NOTHING`.
  - The primary-key index `pk_message_receipts` acts as the conflict arbiter.
  - All 5,000 tuples are inserted, with zero conflicting tuples.
  - Foreign-key triggers `fk_receipts_message` and `fk_receipts_user` each execute 5,000 times.
  - The first run records approximately 15.704 ms for the message foreign-key trigger and 16.748 ms for the user foreign-key trigger.
  - Buffer statistics show significant shared-buffer activity and dirty/written buffers.
- **Likely cost driver:** Bulk insertion of 5,000 records and repeated foreign-key validation. The two foreign-key triggers execute 5,000 times each and account for a substantial portion of execution time.

## W05 — Update Chat Member Leave Status

- **Run times (ms):** 0.594 / 0.129 / 0.132
- **Average (ms):** 0.285
- **Main plan nodes:** Update, Index Scan.
- **Target table:** `chat_members`.
- **Plan evidence:**
  - The update uses `pk_chat_members`.
  - Index lookup uses both `chat_id = 20898` and `user_id = 965`.
  - The additional filter checks `left_at IS NULL`.
  - Only one target row is retrieved.
  - Approximately 37–41 shared buffers are hit.
  - Some buffers are dirtied during the update.
- **Likely cost driver:** No significant bottleneck is observed. The composite primary-key index efficiently identifies the target membership record, and only one row requires updating.

---

## 3. Overall observations

1. R19 is the most expensive query, averaging 16,016.644 ms, primarily due to repeated correlated subqueries and sequential scans of the messages table.
2. R20 is affected by external merge sorting and temporary disk I/O while processing 120,000 messages.
3. R17 and R18 involve multiple table scans and hash-based joins, increasing processing work.
4. R21 and R24 perform full-table scans followed by aggregation.
5. R22 uses an index, but still processes a large number of index entries before returning the limited result.
6. R23 and R25 demonstrate relatively efficient execution.
7. W03 and W05 are efficient because they use primary-key indexes to locate individual records.
8. W04 has higher execution time due to bulk insertion and repeated foreign-key constraint checks.

**Conclusion:** The baseline execution plans show that repeated sequential scans, correlated subqueries, large intermediate results, sorting and foreign-key validation are important contributors to query execution cost. R19 is the most significant performance concern in the assigned query set.