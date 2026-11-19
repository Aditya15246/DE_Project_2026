-- CP3: indexes justified by baseline EXPLAIN (ANALYZE, BUFFERS) plans.
SET search_path TO whatsapp;

-- R13: locate replies efficiently when checking unanswered questions.
CREATE INDEX IF NOT EXISTS idx_messages_reply_to
ON messages (reply_to_message_id)
WHERE reply_to_message_id IS NOT NULL;

-- R14, R17: June date-range filtering and message-type analytics.
CREATE INDEX IF NOT EXISTS idx_messages_sent_at_chat_sender
ON messages (sent_at, chat_id, sender_id);

-- R01, R02, R19: chat message lookup and latest-message ordering.
CREATE INDEX IF NOT EXISTS idx_messages_chat_sent_at
ON messages (chat_id, sent_at DESC);

-- R18: find active group memberships by user.
CREATE INDEX IF NOT EXISTS idx_chat_members_active_user_chat
ON chat_members (user_id, chat_id)
WHERE left_at IS NULL;

-- R18: locate users by last-seen cutoff.
CREATE INDEX IF NOT EXISTS idx_users_last_seen
ON users (last_seen_at);

-- R23: filter inactive WEB/DESKTOP devices.
CREATE INDEX IF NOT EXISTS idx_devices_web_desktop_last_active
ON devices (last_active_at)
WHERE device_type IN ('WEB', 'DESKTOP');

-- R24: group duplicate media by SHA-256.
CREATE INDEX IF NOT EXISTS idx_media_sha256
ON media (sha256);

-- W02: locate unread receipts for a particular user.
CREATE INDEX IF NOT EXISTS idx_receipts_unread_user_message
ON message_receipts (user_id, message_id)
WHERE read_at IS NULL;

ANALYZE;
