---
slug: database-schema
status: awaiting-approval
intent: clear
review_required: true
pending-action: write .omo/plans/database-schema.md
approach: "Generate a single production-ready MySQL 8 .sql file (uniseek_schema.sql) in the project root, containing 13 tables (the original 11 designed by the user + t_complaint + t_operation_log) plus proper FK constraints, indexes, Chinese comments, and seed data."
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
| Foreign key ON DELETE | RESTRICT for mandatory FKs, CASCADE for t_chat_message→t_chat_session→t_task_application chain, SET NULL for optional FKs and self-referencing parent_id | Data integrity — prevent orphaned records; CASCADE for chat chain (application→session→message) is safe because chat lifecycle follows application lifecycle | Schema-level, requires migration |
| Missing timestamps | Add `create_time` to t_resume / t_category / t_region; add `update_time` to t_enterprise | Standard audit trail for mutable records | Yes |
| Region seed data | Seed 34 provinces + major cities + districts | Address-based filtering is required in requirements doc | Yes (truncatable) |
| Category seed data | 30 entries across 2-level hierarchy (15 top-level + 15 sub-categories) | Job classification is essential for browsing | Yes |
| Chat feature design | t_chat_session linked 1:1 to t_task_application; t_chat_message restructured: removed `receiver_id`+`application_id`, added `session_id`+`message_type`, switched `VARCHAR(2000)` to `TEXT` | 1-on-1 private chat scoped per application; normalized session table avoids redundant employer/seeker storage per message; `receiver_id` derivable from session participants | Medium — queries for unread messages need JOIN to session table |
| Additional tables | **ADDED `t_complaint` + `t_operation_log`** (2 tables added, total 13) — per user approval after Metis gap analysis | Requirements doc mentions "用户投诉处理" (§3.4.1) and "关键业务操作记录日志" (§4.3) but no tables were defined; adding them ensures full requirement coverage | Yes |
| Missing NOT NULL constraints | Added NOT NULL to t_task.total_quota, t_task.remaining_quota, t_enterprise.company_name, t_enterprise.credit_code | Business-critical fields must not be nullable | Yes |
| Missing AUTO_INCREMENT | Added AUTO_INCREMENT to all 13 table PKs | Required for auto-generated IDs; only t_user had it explicitly | No (would break ID generation) |
| Composite indexes | Added 7 composite indexes: t_task(category_id,status), t_task(region_id,status), t_task_application(task_id,status), t_message(receiver_id,create_time), t_chat_session(employer_id,status), t_chat_session(seeker_id,status), t_chat_message(session_id,send_time) | Optimize common query patterns: category/region filtering, HR pool filtering, paginated inbox, session listing, chat history pagination | Yes (can drop if unused) |
| CHECK constraint | salary_min ≤ salary_max and remaining_quota ≥ 0 documented as business rules in column comments; NOT enforced as DB CHECK | MySQL 8 CHECK constraints have limitations; application-level enforcement is standard practice | N/A |
| Guardrail for MySQL extensions | Changed from "不使用MySQL私有扩展语法" to "不使用已废弃或不推荐使用的特性" | JSON type and FULLTEXT index are MySQL production features needed for resume_snapshot and experience search | N/A |
| **User identity fields** (added per latest user request) | Added `real_name` + `id_card` to `t_user`; `id_card` is UNIQUE with note about encryption; existing `real_name` in `t_resume` retained separately (resume display name vs verified identity) | ID card and verified real name are user-level identity attributes, not resume properties; keeping both allows resume real_name to differ from verified identity name when needed | Yes — encryption strategy for `id_card` should be addressed in application layer |

## Findings (cited - path:lines)
1. **Requirements doc is thorough** — `兼职招聘平台需求规格说明书.md`:907 covers user auth, job seeking, enterprise management, admin operations, chat messaging, statistics. No missing functional areas.
2. **Project is in early stage** — pom.xml is skeleton (JDK 8, no dependencies); no existing SQL files; no existing entities.
3. **User's 11-table schema covers all core flows** — from registration → resume → job posting → application → message → statistics. Chat (t_chat_session, t_chat_message) and location (t_region) are already designed.
4. **Two mentioned admin features lack dedicated tables**: "用户投诉处理" and "关键业务操作记录日志" — likely handled through existing t_message or out-of-band processes. Keeping scope to user's 11 tables.

## Decisions (with rationale)
1. **FK constraint actions**: RESTRICT for mandatory FKs (prevent orphan deletion), CASCADE for t_chat_message→t_chat_session and t_chat_session→t_task_application (cascade delete chain), SET NULL for optional FKs (hr_id, category.parent_id, region.parent_id).
2. **Seed data**: Provide realistic initial data for t_category (30 entries) and t_region (provinces + major cities + districts) so the platform is immediately usable.
3. **Naming**: Follow user's snake_case convention, table prefix `t_`, field `_id` suffix for FKs, `create_time`/`update_time` standard.
4. **t_user.credit_score**: Keep with DEFAULT 100. Add column comment noting business rules (scoring/reduction logic) TBD.
5. **t_task.region_id**: Add FK→t_region.id for geographic filtering (per Metis GAP-1).
6. **t_category.parent_id / t_region.parent_id**: Use DEFAULT NULL instead of DEFAULT 0 to avoid FK constraint violation (per Metis GAP-2/GAP-3).
7. **t_chat_message.send_time vs create_time**: Remove create_time, keep only send_time (per Metis SUG-1 - no redundancy).
8. **t_task.salary_min ≤ salary_max**: Document business constraint in SQL comments (per Metis SUG-3).

## Scope IN
- Complete CREATE DATABASE script for MySQL 8
- **13 tables total**: the original 11 + `t_complaint` (投诉表) + `t_operation_log` (操作日志表)
- All foreign key constraints (with appropriate ON DELETE actions)
- All indexes (PKs, UKs, FKs, full-text, composite indexes including idx_biz_id on t_message)
- Column-level Chinese comments on every table, including business rule annotations
- Initial seed data for t_category (30 entries) and t_region (provinces + major cities + districts)
- DROP TABLE IF EXISTS section (reverse FK order) for idempotent re-runs

## Scope OUT (Must NOT have)
- No stored procedures, triggers, events, or views (user didn't request them)
- No data for business tables (t_user, t_enterprise, t_resume, t_task, etc.)
- No sharding/replication configuration
- No migration tooling (Flyway/Liquibase)
- No ORM mapping files or entity classes

## Open questions
**None** — all decisions resolved via user's approval + Metis findings.

## Approval gate
status: plan-ready
review_status: dual-passed
<!-- Dual high-accuracy review completed and passed -->
<!-- Momus session: ses_0a6d25992ffeEL3M5UC9U2EtzO → OKAY -->
<!-- Oracle session: ses_0a6d24e0effew0tZHTmdPwtZoW → APPROVE -->
