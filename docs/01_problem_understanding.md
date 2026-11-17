
# Problem Understanding — WhatsApp Messaging Database

## 1. Overview

The project aims to improve the performance and reliability of a WhatsApp-like messaging database. The existing database has performance issues affecting users, administrators and internal teams. The objective is to identify these business problems and understand the database operations required to solve them.

## 2. Business Problem Analysis

| ID | Business Need | Stakeholder | Query IDs | Classification |
|---|---|---|---|---|
| P1 | Load the chat list with the latest message and unread counts quickly. | End User | R01, R03 | Customer-facing / Real-time |
| P2 | Retrieve group information and message history efficiently. | End User, Group Admin | R02, R07, W01 | Customer-facing / Real-time |
| P3 | Enable fast message searching and retrieval of message read information and reply threads. | End User | R04, R16, R25 | Customer-facing / Real-time |
| P4 | Provide quick phone number lookup, last-seen information and blocked-user verification. | End User, Security / Platform | R05, R06, R15 | Customer-facing / Real-time |
| P5 | Process pending delivery receipts and update message read status efficiently. | Delivery Service | R08, W02, W04 | Customer-facing / Real-time |
| P6 | Identify questions in groups that have not received replies. | Group Admin | R13 | Reporting / Analytics |
| P7 | Identify suspicious forwarding activity and provide message investigation facilities. | Trust & Safety | R12, R22, W03 | Reporting / Analytics |
| P8 | Identify users consuming large storage space and detect duplicate media uploads. | Storage Team | R09, R24 | Reporting / Analytics |
| P9 | Generate engagement, activity, read-time and message-volume analytics while supporting future growth. | Growth / Product Analytics | R10, R14, R17, R19, R20, R21 | Reporting / Analytics |
| P10 | Manage inactive users, missed calls, unused linked devices and group membership cleanup. | Security / Platform | R11, R18, R23, W05 | Customer-facing / Real-time |

## 3. Problem Classification

**Customer-facing / Real-time:** These operations directly affect user experience and require timely responses, such as loading chats, retrieving messages and updating delivery status.

**Reporting / Analytics:** These operations analyse historical or aggregated data to support monitoring, investigation and business decisions.

Some problems contain multiple types of operations. Their classification is based on their primary business purpose.

## 4. Assumptions

1. An active user is considered a user who has recently performed messaging-related activity. The exact definition must follow the relevant query requirements.
2. Real-time operations should prioritize quick responses because they directly affect user experience.
3. Reporting and analytics operations may process larger volumes of historical data.
4. The word "fast" represents a business expectation, not a fixed response time unless specified by the project.
5. Actual performance must be evaluated using the project's prescribed benchmarking method.
