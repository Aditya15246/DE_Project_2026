
SET search_path TO whatsapp;

-- ============================================================
-- CP3: OPTIMIZED QUERIES
-- Contributor: Aditya
-- Original workload: queries/workload_30.sql
-- ============================================================

-- R01: Chats screen - latest message per active chat
SELECT
    cm.chat_id,
    c.chat_type,
    c.group_name,
    last_msg.sent_at,
    last_msg.body
FROM chat_members cm
JOIN chats c ON c.chat_id = cm.chat_id
CROSS JOIN LATERAL (
    SELECT m.sent_at, m.body
    FROM messages m
    WHERE m.chat_id = cm.chat_id
    ORDER BY m.sent_at DESC
    LIMIT 1
) last_msg
WHERE cm.user_id = 965
  AND cm.left_at IS NULL
ORDER BY last_msg.sent_at DESC;


-- R02: Latest 50 messages of group 22556
SELECT
    message_id, sender_id, sent_at,
    message_type, body, reply_to_message_id
FROM messages
WHERE chat_id = 22556
ORDER BY sent_at DESC
LIMIT 50;


-- R03: Unread message counts per chat
SELECT
    m.chat_id,
    COUNT(*) AS unread
FROM message_receipts r
JOIN messages m ON m.message_id = r.message_id
WHERE r.user_id = 965
  AND r.read_at IS NULL
GROUP BY m.chat_id
ORDER BY unread DESC;


-- R04: Search messages containing meeting
SELECT
    m.chat_id, m.message_id, m.sent_at, m.body
FROM messages m
JOIN chat_members cm
  ON cm.chat_id = m.chat_id
 AND cm.user_id = 965
WHERE m.body ILIKE '%meeting%'
ORDER BY m.sent_at DESC
LIMIT 20;


-- R05: Phone number lookup
SELECT user_id, display_name, status
FROM users
WHERE phone_e164 = '+919000000965';


-- R06: Last seen of direct chat contacts
SELECT
    u.user_id,
    u.display_name,
    u.last_seen_at
FROM chat_members me
JOIN chats c
  ON c.chat_id = me.chat_id
 AND c.chat_type = 'DIRECT'
JOIN chat_members other
  ON other.chat_id = me.chat_id
 AND other.user_id <> me.user_id
JOIN users u
  ON u.user_id = other.user_id
WHERE me.user_id = 965
ORDER BY u.last_seen_at DESC NULLS LAST;


-- R07: Current group members
SELECT
    cm.user_id,
    u.display_name,
    cm.role,
    cm.joined_at
FROM chat_members cm
JOIN users u ON u.user_id = cm.user_id
WHERE cm.chat_id = 22556
  AND cm.left_at IS NULL
ORDER BY cm.role, u.display_name;


-- R08: Undelivered receipts before cutoff
SELECT
    r.message_id,
    r.user_id,
    m.sent_at
FROM message_receipts r
JOIN messages m ON m.message_id = r.message_id
WHERE r.delivered_at IS NULL
  AND m.sent_at < TIMESTAMPTZ '2026-06-30 23:00:00+05:30'
ORDER BY m.sent_at
LIMIT 500;


-- R09: Top 20 users by total media uploaded
SELECT
    uploader_id,
    COUNT(*) AS files,
    ROUND(SUM(size_bytes)::numeric / 1073741824, 3) AS gb
FROM media
GROUP BY uploader_id
ORDER BY SUM(size_bytes) DESC
LIMIT 20;


-- R10: Daily active senders in June 2026
SELECT
    sent_at::date AS day,
    COUNT(DISTINCT sender_id) AS active_senders,
    COUNT(*) AS messages
FROM messages
WHERE sent_at >= TIMESTAMPTZ '2026-06-01 00:00:00+05:30'
  AND sent_at < TIMESTAMPTZ '2026-07-01 00:00:00+05:30'
GROUP BY sent_at::date
ORDER BY day;


-- R11: Missed calls received by user 965 since January 2025
SELECT
    c.call_id,
    c.caller_id,
    c.call_type,
    c.started_at
FROM calls c
WHERE c.status = 'MISSED'
  AND c.caller_id <> 965
  AND c.started_at >= TIMESTAMPTZ '2025-01-01 00:00:00+05:30'
  AND EXISTS (
      SELECT 1
      FROM chat_members cm
      WHERE cm.chat_id = c.chat_id
        AND cm.user_id = 965
  )
ORDER BY c.started_at DESC;


-- R12: Users forwarding at least two messages on the same day
SELECT
    sender_id,
    sent_at::date AS day,
    COUNT(*) AS forwarded
FROM messages
WHERE is_forwarded = TRUE
GROUP BY sender_id, sent_at::date
HAVING COUNT(*) >= 2
ORDER BY forwarded DESC, sender_id;
