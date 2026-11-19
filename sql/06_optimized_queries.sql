-- CP3 optimized workload: R13-R25 and W01-W05.
-- Original queries/workload_30.sql remains unchanged.
SET search_path TO whatsapp;

BEGIN;

-- @R13
-- Keep NOT IN semantics; index reply_to_message_id to accelerate the subquery.
SELECT m.message_id, m.sender_id, m.sent_at, m.body
FROM messages m
WHERE m.chat_id = 20501
AND m.body LIKE '%?%'
AND m.message_id NOT IN (
SELECT r.reply_to_message_id
FROM messages r
);

-- @R14
SELECT m.chat_id, c.group_name,
count(DISTINCT m.sender_id) AS active_members,
count(*) AS messages
FROM messages m
JOIN chats c ON c.chat_id = m.chat_id
AND c.chat_type = 'GROUP'
WHERE m.sent_at >= '2026-06-01'
AND m.sent_at < '2026-07-01'
GROUP BY m.chat_id, c.group_name
ORDER BY active_members DESC, messages DESC
LIMIT 10;

-- @R15
SELECT EXISTS (
SELECT 1
FROM blocked_users
WHERE blocker_id = 3064
AND blocked_id = 17793
) AS is_blocked;

-- @R16
SELECT r.user_id, u.display_name, r.delivered_at, r.read_at
FROM message_receipts r
JOIN users u ON u.user_id = r.user_id
WHERE r.message_id = 119989
ORDER BY r.read_at NULLS LAST;

-- @R17
SELECT m.message_type,
round(avg(EXTRACT(EPOCH FROM (r.read_at - m.sent_at)) / 60), 1)
AS avg_minutes_to_read,
count(*) AS reads
FROM messages m
JOIN message_receipts r ON r.message_id = m.message_id
WHERE r.read_at IS NOT NULL
AND m.sent_at >= '2026-06-01'
AND m.sent_at < '2026-07-01'
GROUP BY m.message_type
ORDER BY avg_minutes_to_read;

-- @R18
SELECT u.user_id, u.display_name, u.last_seen_at
FROM users u
WHERE u.last_seen_at < '2026-04-01'
AND EXISTS (
SELECT 1
FROM chat_members cm
JOIN chats c ON c.chat_id = cm.chat_id
WHERE cm.user_id = u.user_id
AND c.chat_type = 'GROUP'
AND cm.left_at IS NULL
)
ORDER BY u.last_seen_at;

-- @R19
-- Aggregate messages once instead of running two correlated scans per group.
SELECT c.chat_id, c.group_name,
stats.last_message_at,
COALESCE(stats.june_messages, 0) AS june_messages
FROM chats c
LEFT JOIN (
SELECT m.chat_id,
max(m.sent_at) AS last_message_at,
count(*) FILTER (
WHERE m.sent_at >= TIMESTAMPTZ '2026-06-01 00:00:00+05:30'
AND m.sent_at <  TIMESTAMPTZ '2026-07-01 00:00:00+05:30'
) AS june_messages
FROM messages m
GROUP BY m.chat_id
) stats ON stats.chat_id = c.chat_id
WHERE c.chat_type = 'GROUP'
ORDER BY stats.last_message_at DESC NULLS LAST;

-- @R20
SELECT EXTRACT(HOUR FROM sent_at) AS hour,
message_type,
count(*) AS messages
FROM messages
GROUP BY 1, 2
ORDER BY 1, 2;

-- @R21
SELECT message_type,
count(*) AS messages,
round(100.0 * count(*) FILTER (WHERE edited_at IS NOT NULL)
/ count(*), 2) AS edited_pct,
round(100.0 * count(*) FILTER (WHERE is_deleted)
/ count(*), 2) AS deleted_pct
FROM messages
GROUP BY message_type
ORDER BY messages DESC;

-- @R22
SELECT message_id, chat_id, sender_id, message_type, sent_at
FROM messages
ORDER BY message_id DESC
OFFSET 100000
LIMIT 25;

-- @R23
SELECT d.device_id, d.user_id, d.device_type, d.last_active_at
FROM devices d
WHERE d.device_type IN ('WEB', 'DESKTOP')
AND d.last_active_at < '2026-06-01'
ORDER BY d.last_active_at;

-- @R24
SELECT sha256, count(*) AS copies, sum(size_bytes) AS total_bytes
FROM media
GROUP BY sha256
HAVING count(*) > 1
ORDER BY copies DESC;

-- @R25
WITH RECURSIVE thread AS (
SELECT message_id, reply_to_message_id, sender_id, body, 0 AS depth
FROM messages
WHERE message_id = 119989

UNION ALL

SELECT m.message_id, m.reply_to_message_id, m.sender_id,
m.body, t.depth + 1
FROM messages m
JOIN thread t ON m.message_id = t.reply_to_message_id
)
SELECT * FROM thread
ORDER BY depth DESC;

-- @W01
INSERT INTO messages
(message_id, chat_id, sender_id, sent_at, message_type, body)
VALUES
(90000001, 22556, 965,
'2026-07-01 09:00:00+05:30', 'TEXT', 'Good morning everyone');

-- @W02
UPDATE message_receipts r
SET read_at = TIMESTAMPTZ '2026-07-01 09:05:00+05:30',
delivered_at = COALESCE(
r.delivered_at,
TIMESTAMPTZ '2026-07-01 09:05:00+05:30'
)
FROM messages m
WHERE m.message_id = r.message_id
AND m.chat_id = 22556
AND r.user_id = 965
AND r.read_at IS NULL;

-- @W03
UPDATE messages
SET is_deleted = TRUE,
body = NULL,
media_id = NULL
WHERE message_id = 119989;

-- @W04
INSERT INTO message_receipts (message_id, user_id)
SELECT 1, g
FROM generate_series(2, 5001) AS g
ON CONFLICT (message_id, user_id) DO NOTHING;

-- @W05
UPDATE chat_members
SET left_at = TIMESTAMPTZ '2026-07-01 10:00:00+05:30'
WHERE chat_id = 20898
AND user_id = 965
AND left_at IS NULL;

-- @END
ROLLBACK;
