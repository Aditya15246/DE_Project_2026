SET search_path TO whatsapp;

\copy whatsapp.users FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/users.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.chats FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/chats.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.media FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/media.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.devices FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/devices.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.chat_members FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/chat_members.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.blocked_users FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/blocked_users.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.messages FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/messages.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.message_receipts FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/message_receipts.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy whatsapp.calls FROM '/Users/anshgupta/Documents/DE_Project_2026/DE_Project_2026/seed_data/calls.csv' WITH (FORMAT CSV, HEADER TRUE);
