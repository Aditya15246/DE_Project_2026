# CP3 Baseline Query Timings

Baseline measurements use EXPLAIN (ANALYZE, BUFFERS), with three runs per query.
The average execution times below are in milliseconds.

| Query | Type | Average (ms) | Baseline observation |
|---|---|---:|---|
| R13 | READ | 25.126 | Sequential scans of messages for questions and replies |
| R14 | READ | 6.738 | Sequential scans of messages and chats |
| R15 | READ | 0.092 | Primary-key lookup on blocked_users |
| R16 | READ | 0.389 | Primary-key lookups on receipts and users |
| R17 | READ | 22.375 | Parallel sequential scans of receipts and messages |
| R18 | READ | 15.825 | Sequential scans of users, chat_members and chats |
| R19 | READ | 16016.644 | Correlated subqueries repeatedly scan messages for each group |
| R20 | READ | 48.435 | Full sequential scan and aggregation of messages |
| R21 | READ | 12.766 | Full sequential scan and aggregation of messages |
| R22 | READ | 10.256 | Backward primary-key scan with OFFSET 100000 |
| R23 | READ | 3.854 | Sequential scan of devices |
| R24 | READ | 8.102 | Sequential scan and grouping of media |
| R25 | READ | 0.054 | Primary-key lookup for recursive reply traversal |
| W01 | WRITE | 0.603 | Single-row insert |
| W02 | WRITE | 11.651 | Message lookup followed by receipt updates |
| W03 | WRITE | 0.449 | Primary-key update |
| W04 | WRITE | 39.268 | Bulk insert of 5,000 receipts |
| W05 | WRITE | 0.285 | Membership update |

## Main bottlenecks

- R19 was the dominant bottleneck. Its correlated subqueries repeatedly scanned the messages table for each group.
- R13 scanned messages to identify replies and unanswered questions.
- R17 scanned receipts and messages for June read-time analytics.
- R18 scanned membership and user data to identify inactive users in groups.
- R20 and R21 required full-table aggregation.
- R22 used a large OFFSET, requiring the database to walk past 100,000 rows.
- R23 scanned devices to find inactive WEB and DESKTOP devices.
- W02 required locating unread receipts for one user in one chat.
- W04 inserted 5,000 rows and maintained the receipt primary-key index.

