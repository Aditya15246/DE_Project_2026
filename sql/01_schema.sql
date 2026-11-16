CREATE SCHEMA IF NOT EXISTS whatsapp;

SET search_path TO whatsapp;

-- Remove existing tables when rebuilding the schema.
-- Run this only when you intend to reset the project.

-- DROP TABLE IF EXISTS whatsapp.message_receipts CASCADE;
-- DROP TABLE IF EXISTS whatsapp.messages CASCADE;
-- DROP TABLE IF EXISTS whatsapp.calls CASCADE;
-- DROP TABLE IF EXISTS whatsapp.blocked_users CASCADE;
-- DROP TABLE IF EXISTS whatsapp.chat_members CASCADE;
-- DROP TABLE IF EXISTS whatsapp.devices CASCADE;
-- DROP TABLE IF EXISTS whatsapp.media CASCADE;
-- DROP TABLE IF EXISTS whatsapp.chats CASCADE;
-- DROP TABLE IF EXISTS whatsapp.users CASCADE;


-- =====================================================
-- 1. USERS
-- =====================================================

CREATE TABLE whatsapp.users (
    user_id BIGINT PRIMARY KEY,
    phone_e164 VARCHAR(20) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    about TEXT,
    is_business BOOLEAN NOT NULL DEFAULT FALSE,
    joined_on DATE NOT NULL,
    last_seen_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT chk_users_status
        CHECK (status IN ('ACTIVE', 'BANNED', 'DELETED'))
);


-- =====================================================
-- 2. CHATS
-- =====================================================

CREATE TABLE whatsapp.chats (
    chat_id BIGINT PRIMARY KEY,
    chat_type VARCHAR(10) NOT NULL,
    group_name VARCHAR(100),
    created_by BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_chats_created_by
        FOREIGN KEY (created_by)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT chk_chats_type
        CHECK (chat_type IN ('DIRECT', 'GROUP')),

    CONSTRAINT chk_chats_group_name
        CHECK (
            (chat_type = 'DIRECT' AND group_name IS NULL)
            OR
            (chat_type = 'GROUP' AND group_name IS NOT NULL)
        )
);



-- =====================================================
-- 3. MEDIA
-- =====================================================

CREATE TABLE whatsapp.media (
    media_id BIGINT PRIMARY KEY,
    uploader_id BIGINT NOT NULL,
    media_type VARCHAR(20) NOT NULL,
    mime_type TEXT NOT NULL,
    size_bytes BIGINT NOT NULL,
    sha256 TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_media_uploader
        FOREIGN KEY (uploader_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT chk_media_type
        CHECK (
            media_type IN (
                'AUDIO',
                'DOCUMENT',
                'IMAGE',
                'VIDEO'
            )
        )
);


-- =====================================================
-- 4. DEVICES
-- =====================================================

CREATE TABLE whatsapp.devices (
    device_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device_type VARCHAR(20) NOT NULL,
    app_version TEXT NOT NULL,
    registered_at TIMESTAMPTZ NOT NULL,
    last_active_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_devices_user
        FOREIGN KEY (user_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT chk_devices_type
        CHECK (
            device_type IN (
                'ANDROID',
                'DESKTOP',
                'IOS',
                'WEB'
            )
        )
);


-- =====================================================
-- 5. CHAT MEMBERS
-- =====================================================

CREATE TABLE whatsapp.chat_members (
    chat_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL,
    left_at TIMESTAMPTZ,
    is_muted BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_chat_members
        PRIMARY KEY (chat_id, user_id),

    CONSTRAINT fk_chat_members_chat
        FOREIGN KEY (chat_id)
        REFERENCES whatsapp.chats(chat_id),

    CONSTRAINT fk_chat_members_user
        FOREIGN KEY (user_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT chk_chat_members_role
        CHECK (role IN ('ADMIN', 'MEMBER')),

    CONSTRAINT chk_chat_members_dates
        CHECK (left_at IS NULL OR left_at >= joined_at)
);


-- =====================================================
-- 6. BLOCKED USERS
-- =====================================================

CREATE TABLE whatsapp.blocked_users (
    blocker_id BIGINT NOT NULL,
    blocked_id BIGINT NOT NULL,
    blocked_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT pk_blocked_users
        PRIMARY KEY (blocker_id, blocked_id),

    CONSTRAINT fk_blocked_users_blocker
        FOREIGN KEY (blocker_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT fk_blocked_users_blocked
        FOREIGN KEY (blocked_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT chk_blocked_users_not_self
        CHECK (blocker_id <> blocked_id)
);


-- =====================================================
-- 7. MESSAGES
-- =====================================================

CREATE TABLE whatsapp.messages (
    message_id BIGINT PRIMARY KEY,
    chat_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL,
    message_type VARCHAR(20) NOT NULL,
    body TEXT,
    media_id BIGINT,
    reply_to_message_id BIGINT,
    is_forwarded BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    edited_at TIMESTAMPTZ,

    CONSTRAINT fk_messages_chat
        FOREIGN KEY (chat_id)
        REFERENCES whatsapp.chats(chat_id),

    CONSTRAINT fk_messages_sender
        FOREIGN KEY (sender_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT fk_messages_media
        FOREIGN KEY (media_id)
        REFERENCES whatsapp.media(media_id),

    CONSTRAINT fk_messages_reply
        FOREIGN KEY (reply_to_message_id)
        REFERENCES whatsapp.messages(message_id),

    CONSTRAINT chk_messages_type
        CHECK (
            message_type IN (
                'AUDIO',
                'DOCUMENT',
                'IMAGE',
                'LOCATION',
                'TEXT',
                'VIDEO'
            )
        ),

    CONSTRAINT chk_messages_edit_time
        CHECK (edited_at IS NULL OR edited_at >= sent_at)
);


-- =====================================================
-- 8. MESSAGE RECEIPTS
-- =====================================================

CREATE TABLE whatsapp.message_receipts (
    message_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,

    CONSTRAINT pk_message_receipts
        PRIMARY KEY (message_id, user_id),

    CONSTRAINT fk_receipts_message
        FOREIGN KEY (message_id)
        REFERENCES whatsapp.messages(message_id),

    CONSTRAINT fk_receipts_user
        FOREIGN KEY (user_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT chk_receipts_read_after_delivery
        CHECK (
            read_at IS NULL
            OR delivered_at IS NULL
            OR read_at >= delivered_at
        )
);



-- =====================================================
-- 9. CALLS
-- =====================================================

CREATE TABLE whatsapp.calls (
    call_id BIGINT PRIMARY KEY,
    chat_id BIGINT NOT NULL,
    caller_id BIGINT NOT NULL,
    call_type VARCHAR(10) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    answered_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_calls_chat
        FOREIGN KEY (chat_id)
        REFERENCES whatsapp.chats(chat_id),

    CONSTRAINT fk_calls_caller
        FOREIGN KEY (caller_id)
        REFERENCES whatsapp.users(user_id),

    CONSTRAINT chk_calls_type
        CHECK (call_type IN ('VOICE', 'VIDEO')),

    CONSTRAINT chk_calls_status
        CHECK (
            status IN ('COMPLETED', 'FAILED', 'MISSED', 'REJECTED')
        ),

    CONSTRAINT chk_calls_answered_time
        CHECK (
            answered_at IS NULL
            OR answered_at >= started_at
        ),

    CONSTRAINT chk_calls_ended_time
        CHECK (
            ended_at IS NULL
            OR ended_at >= started_at
        )
);
