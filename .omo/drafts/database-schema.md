---
slug: database-schema
status: awaiting-approval
intent: clear
review_required: false
pending-action: write .omo/plans/database-schema.md
approach: "Generate a single production-ready MySQL 8 .sql file (uniseek_schema.sql) in the project root, containing all 11 tables designed by the user plus proper FK constraints, indexes, Chinese comments, and seed data."
---

# Draft: database-schema

## Components (topology ledger)
| id | outcome | status | evidence path |
|----|---------|--------|--------------|
| 1-database-schema.sql | A single .sql file with all DDL + seed data | active | `兼职招聘平台需求规格说明书.md` (full doc, 907 lines) + user's inline schema in the request |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|------------|-----------------|-----------|-------------|
| Character set | utf8mb4 + utf8mb4_unicode_ci | MySQL 8 best practice for full CJK/emoji support | Yes (drop/recreate) |
| Storage engine | InnoDB | Transactional, FK support, row-level locking | No (would lose FK constraints) |
| Foreign key ON DELETE | RESTRICT for mandatory FKs, CASCADE only for t_chat_message→t_chat_session, SET NULL for optional FKs | Data integrity — prevent orphaned records | Schema-level, requires migration |
| Missing timestamps | Add `create_time` to t_resume / t_category / t_region; add `update_time` to t_enterprise | Standard audit trail for mutable records | Yes |
| Region seed data | Seed 34 provinces + major cities + districts | Address-based filtering is required in requirements doc | Yes (truncatable) |
| Category seed data | 30 entries across 2-level hierarchy (15 top-level + 15 sub-categories) | Job classification is essential for browsing | Yes |
| Chat feature design | t_chat_session linked 1:1 to t_task_application; t_chat_message with text/image types | 1-on-1 private chat between seeker and HR, scoped per application | Yes |
| No additional tables beyond the user's 11 | No t_operation_log / t_complaint added | User's design is comprehensive; keeping scope contained | N/A |

## Findings (cited - path:lines)
1. **Requirements doc is thorough** — `兼职招聘平台需求规格说明书.md`:907 covers user auth, job seeking, enterprise management, admin operations, chat messaging, statistics. No missing functional areas.
2. **Project is in early stage** — pom.xml is skeleton (JDK 8, no dependencies); no existing SQL files; no existing entities.
3. **User's 11-table schema covers all core flows** — from registration → resume → job posting → application → message → statistics. Chat (t_chat_session, t_chat_message) and location (t_region) are already designed.
4. **Two mentioned admin features lack dedicated tables**: "用户投诉处理" and "关键业务操作记录日志" — likely handled through existing t_message or out-of-band processes. Keeping scope to user's 11 tables.

## Decisions (with rationale)
1. **FK constraint actions**: RESTRICT for mandatory FKs (prevent orphan deletion), CASCADE for t_chat_message (session deletion cascades to messages), SET NULL for optional FKs (hr_id, category.parent_id).
2. **Seed data**: Provide realistic initial data for t_category (30 entries) and t_region (provinces + major cities + districts) so the platform is immediately usable.
3. **Naming**: Follow user's snake_case convention, table prefix `t_`, field `_id` suffix for FKs, `create_time`/`update_time` standard.

## Scope IN
- Complete CREATE DATABASE script for MySQL 8
- 11 tables: t_user, t_enterprise, t_resume, t_category, t_task, t_task_application, t_message, t_chat_session, t_chat_message, t_statistics_daily, t_region
- All foreign key constraints (with appropriate ON DELETE actions)
- All indexes (PKs, UKs, FKs, full-text, composite indexes)
- Column-level Chinese comments on every table
- Initial seed data for t_category and t_region
- DROP TABLE IF EXISTS section (reverse FK order) for idempotent re-runs

## Scope OUT (Must NOT have)
- No stored procedures, triggers, events, or views (user didn't request them)
- No data for business tables (t_user, t_enterprise, t_resume, t_task, etc.)
- No sharding/replication configuration
- No migration tooling (Flyway/Liquibase)
- No ORM mapping files or entity classes

## Open questions
**None** — all design decisions are covered by the user's specification or defensible defaults.

## Approval gate
status: awaiting-approval
<!-- Wait for user approval before writing .omo/plans/database-schema.md and the .sql file. -->
