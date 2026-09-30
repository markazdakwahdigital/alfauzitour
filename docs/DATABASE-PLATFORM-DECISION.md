# Database Platform Decision — Phase 2

Date: 2026-09-30
Status: proposed baseline for development/staging

## Decision
Use managed PostgreSQL as the primary transactional database. For the current Al Fauzi Tour stage, the baseline implementation target is Supabase Postgres for development/staging because it combines full PostgreSQL, connection pooling, Auth/Storage/Realtime capabilities, and a practical path for a small team. The schema remains standard PostgreSQL and vendor-neutral so migration to another managed PostgreSQL provider remains possible.

This decision does not create a production database yet.

## Environment separation
- local/test: disposable PostgreSQL
- staging: isolated managed PostgreSQL project, synthetic/non-production data
- production: separate project/credentials/database; never share staging credentials

## Connection rules
- Browser/PWA never receives a privileged PostgreSQL connection string.
- Application mutations go through the backend/API boundary.
- Use a connection pooler for serverless/high-concurrency application traffic.
- Migrations/admin jobs use an appropriately protected administrative connection.
- Secrets live in environment/secret management, never in Git.

## Recovery baseline
Production readiness requires:
- automated database backups
- point-in-time recovery when supported by selected plan
- documented restore procedure
- periodic restore drill
- separate backup policy for object storage because DB backup does not imply file-object backup

## Scale gates
Do not add Redis/read replicas/microservices merely because they exist. Add them after measurements show a bottleneck. Before production, measure API p95/p99, DB CPU, connection saturation, slow queries, lock waits, queue lag, error rate, and sync retry rate.

## Exit criteria for Phase 2
1. migration applies cleanly to a disposable PostgreSQL instance
2. schema smoke tests pass
3. staging database is provisioned
4. migration applies cleanly to staging
5. seed data can be loaded without production data
6. backup/restore procedure is tested
7. concurrent booking/payment tests pass
8. rollback/forward-fix procedure is documented
