
SET search_path TO whatsapp;

-- ============================================================
-- CP3: PROPOSED INDEXES
-- Contributor: Aditya
-- Coordinate these indexes with Piyush before integration.
-- ============================================================

-- R01, R02: Latest messages within a chat
CREATE INDEX IF NOT EXISTS idx_messages_chat_sent_at
ON messages (chat_id, sent_at DESC);

-- R03: Unread receipts belonging to a user
CREATE INDEX IF NOT EXISTS idx_receipts_unread_user
ON message_receipts (user_id, message_id)
WHERE read_at IS NULL;

-- R06: Find memberships belonging to a user
CREATE INDEX IF NOT EXISTS idx_chat_members_user_chat
ON chat_members (user_id, chat_id);

-- R08: Undelivered receipts
CREATE INDEX IF NOT EXISTS idx_receipts_undelivered
ON message_receipts (message_id)
WHERE delivered_at IS NULL;

-- R10: June date-range message filtering
CREATE INDEX IF NOT EXISTS idx_messages_sent_at_sender
ON messages (sent_at, sender_id);

-- R11: Missed calls by chat and start time
CREATE INDEX IF NOT EXISTS idx_calls_missed_chat_started
ON calls (chat_id, started_at DESC)
WHERE status = 'MISSED';

-- R12: Forwarded messages grouped by sender and date
CREATE INDEX IF NOT EXISTS idx_messages_forwarded_sender_date
ON messages (sender_id, sent_at)
WHERE is_forwarded = TRUE;