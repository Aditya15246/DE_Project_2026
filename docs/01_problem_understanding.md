# Problem Understanding — WhatsApp Messaging Database

## 1. Project Overview

The project focuses on improving the performance, reliability and scalability of a WhatsApp-like messaging database. The existing database has several performance issues affecting end users, group administrators and internal teams. Our objective is to understand these business requirements and identify the database operations needed to address them.

## 2. Business Problem Analysis

| ID | Business Requirement | Affected Stakeholder | Related Queries | Classification |
|---|---|---|---|---|
| P1 | Improve chat list loading by retrieving the latest message and unread counts efficiently. | End User | R01, R03 | Customer-facing / Real-time |
| P2 | Make group information and message history accessible without delays. | End User, Group Admin | R02, R07, W01 | Customer-facing / Real-time |
| P3 | Improve message searching, read-status retrieval and navigation through reply threads. | End User | R04, R16, R25 | Customer-facing / Real-time |
| P4 | Provide quick phone number verification, contact last-seen information and blocked-user checks. | End User, Security / Platform | R05, R06, R15 | Customer-facing / Real-time |
| P5 | Improve the processing of pending delivery receipts and updates to message read status. | Delivery Service | R08, W02, W04 | Customer-facing / Real-time |
| P6 | Generate an accurate list of unanswered questions within a group for administrators. | Group Admin | R13 | Reporting / Analytics |
| P7 | Support the identification of suspicious forwarding patterns and provide efficient message investigation facilities. | Trust & Safety | R12, R22, W03 | Reporting / Analytics |
| P8 | Identify users with high media-upload consumption and detect duplicate media files to help manage storage costs. | Storage Team | R09, R24 | Reporting / Analytics |
| P9 | Improve analytical reports covering user activity, engagement, reading behaviour, message modifications and system workload. | Growth / Product Analytics | R10, R14, R17, R19, R20, R21 | Reporting / Analytics |
| P10 | Improve security and maintenance operations involving inactive users, missed calls, unused linked devices and group membership changes. | Security / Platform | R11, R18, R23, W05 | Customer-facing / Real-time |

## 3. Classification of Business Requirements

**Customer-facing / Real-time:**
These operations directly influence the application experience or immediate system behaviour. They include loading conversations, retrieving messages, checking user information and processing message-status updates. Timely execution is important to avoid delays in normal application operations.

**Reporting / Analytics:**
These operations involve examining historical records, identifying patterns and generating aggregated information. They support administrative monitoring, security investigations, storage management and product-related decisions. They generally have different response-time expectations from direct user interactions.

Some problem areas contain multiple types of operations. Their classification above reflects their primary business purpose, not necessarily the execution requirements of every individual query.

## 4. Assumptions

1. An active user refers to an account with recent messaging-related activity; the exact definition depends on the relevant project query.
2. Customer-facing operations are expected to prioritize timely responses because they directly influence user experience.
3. Reporting and analytical operations may involve processing larger volumes of historical data.
4. Terms such as "fast" and "instant" represent business expectations unless a specific performance target is defined in the project requirements.
5. Actual database performance should be evaluated using the prescribed benchmarking method rather than estimated values.

---

**Prepared by:** Rohit Raj  
**Project:** WhatsApp Messaging Database — DBMS