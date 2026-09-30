# Al Fauzi Tour — Architecture Foundation v1

## Tujuan
Fondasi ini menyiapkan aplikasi multi-user Pusat, Cabang, Agen, dan Jamaah agar dapat berkembang tanpa menjadikan browser, Google Sheets, atau UI sebagai sumber kebenaran data.

## Prinsip inti
1. Primary data store harus database transaksional SQL/PostgreSQL.
2. Semua mutasi melalui API. Frontend tidak menulis langsung ke database.
3. Setiap mutasi memiliki request ID dan idempotency key.
4. Operasi lintas-record menggunakan transaction.
5. Pekerjaan lambat (notifikasi, PDF, ekspor, analytics) dipindahkan ke queue/worker.
6. IndexedDB hanya untuk draft, cache, dan outbox offline; server tetap source of truth.
7. Konflik update dikontrol dengan version/updated_at dan HTTP 409.
8. Hak akses diverifikasi di server, bukan hanya menyembunyikan menu di frontend.
9. File besar disimpan di object storage; database menyimpan metadata dan URL/key.
10. Semua aksi sensitif menghasilkan audit log.

## Boundary sistem
Frontend PWA -> API Gateway -> Auth/RBAC -> Domain Services -> PostgreSQL
                                      |-> Queue/Worker
                                      |-> Object Storage
                                      |-> Cache (saat dibutuhkan)
                                      |-> Audit/Observability

## Domain awal
- identity: users, roles, permissions, sessions
- organization: pusat, cabang
- sales: agents, jamaah, packages, bookings
- departure: departures, manifests, rooms, transport, hotels
- finance: invoices, payments, transactions
- documents: jamaah documents and generated files
- platform: audit_logs, idempotency_keys, outbox_events, notifications

## Aturan concurrency
Setiap entity mutable memiliki id, version, created_at, updated_at.
Update mengirim expectedVersion. Server hanya menerima bila version masih sama, lalu menaikkan version. Bila berbeda, server mengembalikan 409 Conflict.

## Aturan idempotency
POST/command penting wajib membawa Idempotency-Key. Server menyimpan hasil request untuk key tersebut dalam periode tertentu sehingga retry tidak membuat booking/pembayaran ganda.

## Sync/offline
Draft -> IndexedDB -> Outbox -> API -> ACK -> hapus item outbox.
Retry memakai exponential backoff + jitter dan jumlah percobaan terbatas. Error validasi/konflik tidak di-retry tanpa tindakan user.

## Performance budget awal
- shell UI harus dapat dimuat dari cache PWA
- interaksi lokal tidak menunggu network
- API umum ditargetkan p95 <= 500 ms pada kondisi normal, diverifikasi dengan load test
- query list wajib pagination/cursor
- dashboard memakai summary/aggregate, bukan scan seluruh transaksi
- upload file langsung ke object storage via signed URL

## Tahapan
Phase 1 architecture foundation
Phase 2 database schema + migration
Phase 3 authentication + RBAC
Phase 4 API foundation
Phase 5 sync engine + offline outbox
Phase 6 core operational modules
Phase 7 finance/manifest/agent
Phase 8 realtime/notification
Phase 9 security hardening
Phase 10 load/concurrency test
