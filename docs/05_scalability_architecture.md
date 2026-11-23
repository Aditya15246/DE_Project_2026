# 100× Scalability Architecture Proposal
## CP4 – WhatsApp Messaging Database
**Prepared by:** Piyush  
**Repository:** DE_Project_2026  
**Purpose:** Architecture proposal for future database scalability

---

## 1. Introduction

The WhatsApp messaging database currently uses a relational PostgreSQL design. The Phase 5 project brief anticipates approximately 20× data growth, including approximately 2.4 million messages, 10 million message receipts, 600,000 users and 460,000 chats.

This document proposes an architecture that can evolve towards 100× the current seed-data volume.

The design focuses on:

- Horizontal sharding of messages.
- Read replicas for read-heavy workloads.
- Caching frequently requested data.
- Database maintenance and vacuum operations.
- Archiving historical messages.
- Summary tables for analytical workloads.

The proposed architecture is a future design, not a claim that these capabilities have already been implemented or benchmarked.

## 2. Sharding Strategy Comparison

Sharding distributes database records across multiple database servers. The shard key determines where each record is stored.

Three possible shard keys are considered.

### 2.1 Sharding by chat_id

Messages belonging to the same chat are assigned to the same shard using a deterministic hash of chat_id.

**Advantages:**
- Messages belonging to one conversation remain together.
- R02, which retrieves the history of one chat, can be routed to a single shard.
- Message ordering and pagination are easier within a conversation.
- New messages can be written directly to the shard responsible for the chat.

**Disadvantages:**
- R01, which retrieves a user's chat list, may involve several shards because a user can participate in many chats.
- Very active group chats can become hotspots.
- Large groups can create uneven storage and write workloads.

### 2.2 Sharding by sender_id

Messages are distributed according to the user who sent them.

**Advantages:**
- A user's sent-message history can be retrieved locally.
- Sender-specific activity and usage reports may be easier to execute.
- Writes can be routed using the sender's identity.

**Disadvantages:**
- Messages belonging to one chat are distributed across multiple shards.
- R02 requires gathering messages from several shards.
- Conversations require distributed sorting and aggregation.
- A highly active sender may create a hotspot.

### 2.3 Sharding by recipient/user_id

Records are distributed according to the receiving user or user identity associated with the conversation.

**Advantages:**
- User-specific inbox and recipient activity lookups can be localized.
- Some user-facing retrieval operations can access a single shard.
- Recipient-oriented workloads can be distributed across users.

**Disadvantages:**
- Group conversations have multiple recipients.
- The same message may need to be represented or accessed across multiple user partitions.
- R02 becomes a cross-shard operation.
- Duplicate storage and distributed consistency become more complicated if messages are copied to recipient shards.

### 2.4 Comparison

| Criterion | chat_id | sender_id | recipient/user_id |
|---|---|---|---|
| R01 – User chat list | Cross-shard possible | Cross-shard possible | Potentially local |
| R02 – One chat history | Local | Cross-shard | Cross-shard |
| Message ordering | Easier | Distributed | Distributed |
| Group conversations | Natural grouping | Distributed | Distributed |
| Write distribution | Chat-based | Sender-based | User-based |
| Main risk | Hot chats | Active senders | Group duplication |

## 3. Recommended Sharding Architecture

### 3.1 Recommendation: Hash-based chat_id sharding

The recommended strategy is hash-based sharding using chat_id.

The primary reason is that messages are fundamentally organized around conversations. Keeping one conversation on a single shard makes message retrieval, ordering, pagination and conversation-level operations more efficient.

A routing function can determine the destination shard:

`shard_id = hash(chat_id) % N`

Here, N represents the number of logical shards. A production deployment should use a consistent hashing or shard-directory approach so that adding servers does not require unnecessary redistribution of all records.

### 3.2 R01 – User chat list

The project's business requirements identify R01 as a user-facing operation involving:

- Retrieving the user's chats.
- Finding the latest message.
- Retrieving unread counts.

A user may participate in chats distributed across different shards.

The application should:

1. Retrieve the user's active chat memberships.
2. Identify the corresponding chat IDs.
3. Route requests to the relevant chat shards.
4. Retrieve latest-message and unread-count information.
5. Merge the results and order the final chat list.

A distributed fan-out request can increase latency. To reduce this cost, maintain a user-chat directory containing user_id, chat_id and the shard identifier.

Frequently requested latest-message and chat-summary information can also be maintained in a separate summary structure.

### 3.3 R02 – History of one chat

R02 retrieves the message history of one conversation.

Using chat_id as the shard key allows the application to identify the correct shard directly.

The request can be routed to one shard without gathering messages from all database servers.

Messages should be ordered using sent_at and a unique tie-breaker such as message_id. Keyset pagination can retrieve subsequent pages without repeatedly scanning large OFFSET ranges.

### 3.4 Routing and aggregation

A routing layer should:

- Maintain the mapping between chat IDs and logical shards.
- Route message inserts to the correct shard.
- Route history requests directly to the owning shard.
- Fan out user chat-list requests when necessary.
- Merge results while preserving ordering.
- Handle shard failures and retries.

The message_receipts table requires special attention because its current key is (message_id, user_id), rather than chat_id.

A message-to-chat mapping or routing directory can identify the owning message shard. Receipt records should be colocated with their corresponding messages where practical, while user-level receipt operations use the routing directory.

Global identifiers and cross-shard relationships must be managed carefully. PostgreSQL foreign keys do not automatically enforce referential integrity across independent database servers.

### 3.5 Sharding trade-offs

Chat-based sharding improves conversation locality but does not make every operation local.

The main remaining challenges are:

- Distributed user chat-list retrieval.
- Hotspot management for highly active chats.
- Cross-shard user and analytics queries.
- Distributed transactions and consistency.
- Rebalancing when new shards are introduced.

The proposed design accepts these trade-offs because conversation history is a central workload of a messaging application.

## 4. Read Replica Architecture

Read replicas maintain copies of data from the primary database through replication.

The primary database remains responsible for writes, while read replicas handle suitable read-heavy workloads.

### 4.1 Queries suitable for replicas

Potential replica workloads include:

| Query / Workload | Recommendation | Reason |
|---|---|---|
| R01 – Chat list | Replica with consistency safeguards | Read-heavy, but may require fresh data |
| R02 – Chat history | Replica when slight lag is acceptable | Frequent history retrieval |
| R09–R10 | Replica | Analytical and reporting workloads |
| R12–R14 | Replica | Investigation and reporting |
| R17–R21 | Replica | Historical analytics |
| R22–R24 | Replica | Search, operational and storage analysis |
| R25 | Replica when appropriate | Historical reply-thread retrieval |

These are proposed routing choices. Actual eligibility depends on freshness requirements and the complete query semantics.

### 4.2 Operations that should use the primary

The following operations should use the primary database:

- W01: inserting a new message.
- W02: updating delivery and read receipts.
- W03: updating message deletion status.
- W04: inserting message receipts.
- W05: updating chat membership.
- Operations requiring immediate read-after-write consistency.
- Security-sensitive checks requiring current committed state.

### 4.3 Replication lag and consistency

Read replicas may temporarily contain older data than the primary.

This creates risks for:

- Newly sent messages.
- Unread counts.
- Delivery receipts.
- Read receipts.
- Membership changes.

The application should route read-after-write requests to the primary or use an appropriate replication-position consistency mechanism.

Replica lag should be monitored continuously. If a replica falls behind beyond the application's acceptable freshness threshold, the application should temporarily route sensitive reads elsewhere.

## 5. Caching Strategy

Caching reduces repeated database reads by storing frequently accessed information in a faster data store.

A distributed cache such as Redis can be introduced alongside PostgreSQL.

### 5.1 Cache candidates

| Data | Suggested TTL | Invalidation strategy |
|---|---|---|
| Chat metadata | 5 minutes | Invalidate on chat updates |
| Group information | 5 minutes | Invalidate on membership or group changes |
| User profile metadata | 10 minutes | Invalidate on profile updates |
| Latest-message summary | 5–15 seconds | Invalidate on new message |
| Chat-list summary | 5–15 seconds | Invalidate on membership or message changes |
| Historical chat data | Longer TTL | Invalidate or version when edited/deleted |

TTL values are initial design suggestions, not measured optimal settings.

### 5.2 Cache invalidation

Cache invalidation should happen when the corresponding database transaction commits.

An event-driven invalidation mechanism can publish events for:

- New messages.
- Message edits and deletion.
- Group membership changes.
- Chat metadata updates.
- User profile changes.

Versioned cache keys or transactional outbox events can help prevent stale cache entries from surviving database updates.

### 5.3 Unread counts and receipts

Unread counts and receipt status are sensitive to stale information.

They should not rely exclusively on long-lived cached values.

For important read-after-write operations, the primary database should be consulted. Short-lived cached summaries may be used for ordinary chat-list display, with refresh or invalidation after receipt updates.

The cache should be treated as a performance layer, not the authoritative source of message state.

## 6. Database Maintenance

As message and receipt volumes increase, PostgreSQL maintenance becomes increasingly important.

### 6.1 VACUUM and autovacuum

PostgreSQL uses MVCC, which means updates and deletes create obsolete row versions that eventually need cleanup.

The messages table may experience frequent updates due to:

- Message deletion.
- Message editing.
- Changes to message metadata.

The message_receipts table may also experience frequent updates when delivery and read timestamps are recorded.

VACUUM and autovacuum should be monitored to prevent excessive dead tuples and table bloat.

### 6.2 Maintenance recommendations

- Monitor dead tuple counts.
- Monitor autovacuum activity and duration.
- Identify tables requiring more frequent cleanup.
- Run ANALYZE after major data loads.
- Monitor index size and index bloat.
- Review slow queries using EXPLAIN (ANALYZE, BUFFERS).
- Monitor long-running transactions that can delay cleanup.
- Consider table-specific autovacuum thresholds based on observed update rates.

No arbitrary global PostgreSQL settings should be applied without workload measurements.

### 6.3 Index maintenance

Indexes improve retrieval speed but increase storage and write costs.

Index usage should be reviewed periodically. Unused or redundant indexes should be identified using actual workload statistics before removal.

## 7. Historical Message Archival

Keeping every message in the active database indefinitely can increase storage requirements and maintenance costs.

A tiered archival strategy is recommended.

### 7.1 Active storage

Recent messages should remain in the primary operational database.

These records support:

- Current conversations.
- Recent message history.
- Delivery and read receipts.
- Frequent application operations.

### 7.2 Historical storage

Older messages can be moved to a historical storage tier according to a defined retention policy.

Possible storage options include:

- Separate PostgreSQL archival databases.
- Time-partitioned historical tables.
- Object storage for exported historical records.

The archival policy must preserve message IDs, chat IDs, timestamps and required historical metadata.

### 7.3 Historical retrieval

When a user requests older messages:

1. The application checks the active database.
2. If the requested date range is archived, it queries the historical storage tier.
3. The results are returned in chronological order.
4. Active and archived records can be combined when a request spans both tiers.

Archival must preserve the application's access-control, deletion and retention requirements.

Message references, reply threads and receipt records must remain resolvable after archival.

## 8. Summary Tables and Materialized Views

Analytical queries often perform aggregations over large numbers of messages and receipts.

Repeatedly calculating these values from operational tables can affect application performance.

Summary tables and materialized views can reduce this cost.

### 8.1 Recommended summary data

Potential summary structures include:

| Summary structure | Stored information | Purpose |
|---|---|---|
| Daily chat activity | Chat ID, date, message count | Chat activity reporting |
| Daily user activity | User ID, date, activity count | Engagement analysis |
| Message-type summary | Message type, total messages | Message distribution |
| Read-time summary | Message type, average read delay | Reading behaviour |
| Media usage summary | User ID, storage consumed | Storage analysis |
| Group activity summary | Chat ID, last message time, message count | Group monitoring |

### 8.2 Refresh strategy

Possible refresh approaches include:

- Scheduled refresh for historical analytics.
- Incremental updates for frequently requested summaries.
- Event-driven updates for selected operational summaries.

Materialized views are useful when periodic freshness is acceptable. Incremental summary tables may be more suitable for frequently changing data.

### 8.3 Trade-offs

Summary structures require additional storage and maintenance.

Their refresh processes must avoid excessive load on the operational database.

The system should clearly document the freshness of each summary and avoid using delayed analytical summaries for operations requiring exact current receipt or unread status.

## 9. Proposed 100× Architecture

The recommended future architecture combines the following components:

1. **Application routing layer:** Routes requests to the correct logical shard.
2. **Hash-based chat sharding:** Keeps each conversation's messages together.
3. **PostgreSQL primary nodes:** Handle message writes and consistency-sensitive operations.
4. **Read replicas:** Handle suitable read-heavy workloads.
5. **Redis caching layer:** Stores frequently requested metadata and short-lived summaries.
6. **Historical archival storage:** Separates older records from active operational data.
7. **Analytical summary layer:** Supports reporting without repeatedly scanning operational tables.
8. **Monitoring and maintenance:** Tracks latency, storage, replication lag, autovacuum and shard utilization.

### 9.1 Conceptual architecture

```text
             CLIENT APPLICATIONS
                      |
                      v
             APPLICATION LAYER
                      |
                      v
              REQUEST ROUTER
                      |
          +-----------+-----------+
          |                       |
          v                       v
     CACHE LAYER             SHARD DIRECTORY
       (Redis)                     |
                                   v
                         CHAT-BASED ROUTING
                                   |
                 +-----------------+-----------------+
                 |                 |                 |
                 v                 v                 v
              SHARD 1           SHARD 2           SHARD N
                 |                 |                 |
                 v                 v                 v
              PRIMARY           PRIMARY           PRIMARY
                 |                 |                 |
              REPLICAS          REPLICAS          REPLICAS

                      |
                      v
             HISTORICAL STORAGE
                      |
                      v
              ANALYTICAL LAYER
             (Summary tables/views)
```

This is a logical design. Actual deployment topology, shard count and replica count should be determined through workload measurements.

### 9.2 Growth planning

The project brief identifies an expected 20× data increase. The 100× target in this proposal represents a longer-term architectural objective.

The architecture should be evaluated against:

- Message insertion throughput.
- Chat-history retrieval latency.
- User chat-list aggregation latency.
- Receipt update throughput.
- Storage growth.
- Replica lag.
- Cache hit ratio.
- Shard utilization and imbalance.
- Archival retrieval latency.

No 100× throughput or latency improvement is claimed without testing.

## 10. Risks and Limitations

The proposed architecture introduces several operational challenges:

| Risk | Mitigation |
|---|---|
| Hot chat shards | Monitor shard load and consider isolated handling of exceptionally active chats |
| Cross-shard R01 requests | Maintain a user-chat directory and cached summaries |
| Replica lag | Monitor replication delay and route sensitive reads to primary |
| Stale cache values | Use TTL, event-driven invalidation and versioning |
| Archival complexity | Maintain message mappings and historical access paths |
| Distributed transactions | Minimize cross-shard transactions and define consistency boundaries |
| Uneven shard distribution | Monitor storage and traffic and support rebalancing |
| Summary freshness | Define refresh intervals and freshness guarantees |

Partitioning is a complementary technique within individual PostgreSQL databases. Its implementation and partition-pruning evidence are handled separately in the team's partitioning workstream.

## 11. Conclusion

A chat_id-based sharding strategy is recommended because it keeps the history of an individual conversation together and makes R02 easier to route efficiently.

R01 remains a distributed operation because a user's chats may span multiple shards. A user-chat directory and cached chat summaries can reduce the cost of this operation.

Read replicas, caching, database maintenance, historical archival and analytical summary structures provide additional opportunities to scale the system while protecting the performance of normal messaging operations.

The proposed design provides a path towards 100× growth, but its success depends on measured workload characteristics, appropriate shard distribution, replication consistency, storage planning and continuous monitoring.

The current Phase 5 dataset and benchmark results must be used to validate the next-stage design. The architecture described here is a proposal and does not represent measured production scalability.

